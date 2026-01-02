-- Migration 087: Set Adjustment Tracking
-- Tracks all set modifications during workouts for analytics and user experience improvement
-- Created: 2025-12-30

-- ============================================================================
-- 1. CREATE set_adjustments TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS set_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE SET NULL,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_index INTEGER NOT NULL,
    exercise_id UUID REFERENCES exercises(id) ON DELETE SET NULL,
    exercise_name TEXT NOT NULL,
    adjustment_type TEXT NOT NULL CHECK (
        adjustment_type IN (
            'set_removed',
            'set_skipped',
            'sets_reduced',
            'exercise_ended_early',
            'set_edited',
            'set_deleted'
        )
    ),
    original_sets INTEGER NOT NULL,
    adjusted_sets INTEGER NOT NULL,
    reason TEXT CHECK (
        reason IS NULL OR reason IN (
            'fatigue',
            'time_constraint',
            'pain',
            'equipment_issue',
            'other'
        )
    ),
    reason_details TEXT,
    set_number INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE set_adjustments IS 'Tracks all set modifications during workouts for pattern analysis and workout optimization';
COMMENT ON COLUMN set_adjustments.adjustment_type IS 'Type of adjustment: set_removed, set_skipped, sets_reduced, exercise_ended_early, set_edited, set_deleted';
COMMENT ON COLUMN set_adjustments.reason IS 'User-provided reason for adjustment: fatigue, time_constraint, pain, equipment_issue, other';
COMMENT ON COLUMN set_adjustments.metadata IS 'Additional data like performance metrics at time of adjustment';

-- ============================================================================
-- 2. ADD COLUMNS TO workout_logs TABLE
-- ============================================================================

-- Add sets_adjusted column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'workout_logs'
        AND column_name = 'sets_adjusted'
    ) THEN
        ALTER TABLE workout_logs ADD COLUMN sets_adjusted BOOLEAN DEFAULT false;
    END IF;
END $$;

-- Add adjustment_count column if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'workout_logs'
        AND column_name = 'adjustment_count'
    ) THEN
        ALTER TABLE workout_logs ADD COLUMN adjustment_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- Add comments for new columns
COMMENT ON COLUMN workout_logs.sets_adjusted IS 'Whether any sets were adjusted during this workout';
COMMENT ON COLUMN workout_logs.adjustment_count IS 'Total number of set adjustments made during this workout';

-- ============================================================================
-- 3. CREATE INDEXES
-- ============================================================================

-- Primary query index: user lookups with time-based filtering
CREATE INDEX IF NOT EXISTS idx_set_adjustments_user_created
    ON set_adjustments(user_id, created_at DESC);

-- Index for workout-specific queries
CREATE INDEX IF NOT EXISTS idx_set_adjustments_workout_id
    ON set_adjustments(workout_id);

-- Index for workout log associations
CREATE INDEX IF NOT EXISTS idx_set_adjustments_workout_log_id
    ON set_adjustments(workout_log_id);

-- Index for exercise-specific pattern analysis
CREATE INDEX IF NOT EXISTS idx_set_adjustments_exercise_id
    ON set_adjustments(exercise_id);

-- Index for reason-based analytics
CREATE INDEX IF NOT EXISTS idx_set_adjustments_reason
    ON set_adjustments(reason) WHERE reason IS NOT NULL;

-- Index for adjustment type analytics
CREATE INDEX IF NOT EXISTS idx_set_adjustments_type
    ON set_adjustments(adjustment_type);

-- ============================================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE set_adjustments ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. RLS POLICIES
-- ============================================================================

-- Policy: Users can only view their own set adjustments
CREATE POLICY "Users can view own set adjustments"
    ON set_adjustments
    FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Policy: Users can insert their own set adjustments
CREATE POLICY "Users can insert own set adjustments"
    ON set_adjustments
    FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Policy: Users can update their own set adjustments
CREATE POLICY "Users can update own set adjustments"
    ON set_adjustments
    FOR UPDATE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Policy: Users can delete their own set adjustments
CREATE POLICY "Users can delete own set adjustments"
    ON set_adjustments
    FOR DELETE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- ============================================================================
-- 6. CREATE VIEW: v_user_set_adjustment_patterns
-- ============================================================================

-- View showing user's adjustment patterns for analytics
CREATE OR REPLACE VIEW v_user_set_adjustment_patterns
WITH (security_invoker = true)
AS
WITH exercise_adjustments AS (
    -- Aggregate adjustments by exercise for each user
    SELECT
        sa.user_id,
        sa.exercise_id,
        sa.exercise_name,
        COUNT(*) AS total_adjustments,
        SUM(sa.original_sets) AS total_planned_sets,
        SUM(sa.adjusted_sets) AS total_completed_sets,
        ROUND(
            AVG(sa.adjusted_sets::NUMERIC / NULLIF(sa.original_sets, 0) * 100),
            1
        ) AS avg_completion_percentage,
        MODE() WITHIN GROUP (ORDER BY sa.adjustment_type) AS most_common_adjustment_type,
        MODE() WITHIN GROUP (ORDER BY sa.reason) FILTER (WHERE sa.reason IS NOT NULL) AS most_common_reason,
        MIN(sa.created_at) AS first_adjustment,
        MAX(sa.created_at) AS last_adjustment
    FROM set_adjustments sa
    GROUP BY sa.user_id, sa.exercise_id, sa.exercise_name
),
user_totals AS (
    -- Calculate overall user statistics
    SELECT
        sa.user_id,
        COUNT(*) AS total_adjustments,
        COUNT(DISTINCT sa.workout_id) AS workouts_with_adjustments,
        SUM(sa.original_sets) AS total_planned_sets,
        SUM(sa.adjusted_sets) AS total_completed_sets,
        ROUND(
            AVG(sa.adjusted_sets::NUMERIC / NULLIF(sa.original_sets, 0) * 100),
            1
        ) AS overall_completion_percentage,
        -- Reason breakdown
        COUNT(*) FILTER (WHERE sa.reason = 'fatigue') AS fatigue_count,
        COUNT(*) FILTER (WHERE sa.reason = 'time_constraint') AS time_constraint_count,
        COUNT(*) FILTER (WHERE sa.reason = 'pain') AS pain_count,
        COUNT(*) FILTER (WHERE sa.reason = 'equipment_issue') AS equipment_issue_count,
        COUNT(*) FILTER (WHERE sa.reason = 'other') AS other_count,
        COUNT(*) FILTER (WHERE sa.reason IS NULL) AS no_reason_count,
        -- Adjustment type breakdown
        COUNT(*) FILTER (WHERE sa.adjustment_type = 'set_removed') AS sets_removed_count,
        COUNT(*) FILTER (WHERE sa.adjustment_type = 'set_skipped') AS sets_skipped_count,
        COUNT(*) FILTER (WHERE sa.adjustment_type = 'sets_reduced') AS sets_reduced_count,
        COUNT(*) FILTER (WHERE sa.adjustment_type = 'exercise_ended_early') AS exercises_ended_early_count,
        COUNT(*) FILTER (WHERE sa.adjustment_type = 'set_edited') AS sets_edited_count,
        COUNT(*) FILTER (WHERE sa.adjustment_type = 'set_deleted') AS sets_deleted_count
    FROM set_adjustments sa
    GROUP BY sa.user_id
),
reason_rankings AS (
    -- Rank reasons by frequency for each user
    SELECT
        user_id,
        ARRAY_AGG(
            reason ORDER BY reason_count DESC
        ) FILTER (WHERE reason IS NOT NULL) AS reasons_ranked
    FROM (
        SELECT
            user_id,
            reason,
            COUNT(*) AS reason_count
        FROM set_adjustments
        WHERE reason IS NOT NULL
        GROUP BY user_id, reason
    ) reason_counts
    GROUP BY user_id
)
SELECT
    ut.user_id,
    ut.total_adjustments,
    ut.workouts_with_adjustments,
    ut.total_planned_sets,
    ut.total_completed_sets,
    ut.overall_completion_percentage,
    -- Reason breakdown
    ut.fatigue_count,
    ut.time_constraint_count,
    ut.pain_count,
    ut.equipment_issue_count,
    ut.other_count,
    ut.no_reason_count,
    rr.reasons_ranked AS most_common_reasons,
    -- Adjustment type breakdown
    ut.sets_removed_count,
    ut.sets_skipped_count,
    ut.sets_reduced_count,
    ut.exercises_ended_early_count,
    ut.sets_edited_count,
    ut.sets_deleted_count,
    -- Top 5 exercises with most adjustments
    (
        SELECT JSONB_AGG(
            JSONB_BUILD_OBJECT(
                'exercise_id', ea.exercise_id,
                'exercise_name', ea.exercise_name,
                'total_adjustments', ea.total_adjustments,
                'avg_completion_percentage', ea.avg_completion_percentage,
                'most_common_reason', ea.most_common_reason,
                'most_common_adjustment_type', ea.most_common_adjustment_type
            ) ORDER BY ea.total_adjustments DESC
        )
        FROM (
            SELECT * FROM exercise_adjustments e
            WHERE e.user_id = ut.user_id
            ORDER BY e.total_adjustments DESC
            LIMIT 5
        ) ea
    ) AS top_adjusted_exercises
FROM user_totals ut
LEFT JOIN reason_rankings rr ON ut.user_id = rr.user_id;

-- Add comment for view documentation
COMMENT ON VIEW v_user_set_adjustment_patterns IS 'Analytics view showing user set adjustment patterns including frequency by exercise, common reasons, and completion rates';

-- ============================================================================
-- 7. CREATE HELPER FUNCTION FOR UPDATING WORKOUT LOG ADJUSTMENT COUNTS
-- ============================================================================

-- Function to update workout_logs adjustment tracking after an adjustment is recorded
CREATE OR REPLACE FUNCTION update_workout_log_adjustment_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only update if workout_log_id is set
    IF NEW.workout_log_id IS NOT NULL THEN
        UPDATE workout_logs
        SET
            sets_adjusted = true,
            adjustment_count = (
                SELECT COUNT(*)
                FROM set_adjustments
                WHERE workout_log_id = NEW.workout_log_id
            )
        WHERE id = NEW.workout_log_id;
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger to automatically update workout_logs when adjustments are recorded
DROP TRIGGER IF EXISTS trg_update_workout_log_adjustment_stats ON set_adjustments;

CREATE TRIGGER trg_update_workout_log_adjustment_stats
    AFTER INSERT ON set_adjustments
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_log_adjustment_stats();

-- ============================================================================
-- 8. GRANT PERMISSIONS
-- ============================================================================

-- Grant access to authenticated users via API
GRANT SELECT, INSERT, UPDATE, DELETE ON set_adjustments TO authenticated;
GRANT SELECT ON v_user_set_adjustment_patterns TO authenticated;

-- Grant usage to anon for public access patterns if needed
GRANT SELECT ON set_adjustments TO anon;
GRANT SELECT ON v_user_set_adjustment_patterns TO anon;
