-- Migration: 091_rep_accuracy_tracking.sql
-- Purpose: Track actual vs planned reps to address workout accuracy issues
-- Context: User review stated "it told me to do 50 crunches... I could only do 30 crunches
--          but there was no option to input this anywhere so now it says I did 50 crunches when I didn't"
-- Created: 2025-12-30

-- ============================================================================
-- 1. CREATE set_rep_accuracy TABLE
-- Stores detailed per-set rep accuracy data
-- ============================================================================

CREATE TABLE IF NOT EXISTS set_rep_accuracy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_log_id UUID REFERENCES workout_logs(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,

    -- Exercise identification
    exercise_index INTEGER NOT NULL,
    exercise_id TEXT,
    exercise_name TEXT NOT NULL,

    -- Set-specific data
    set_number INTEGER NOT NULL,
    planned_reps INTEGER NOT NULL,
    actual_reps INTEGER NOT NULL,

    -- Computed columns for convenience (using generated columns)
    rep_difference INTEGER GENERATED ALWAYS AS (actual_reps - planned_reps) STORED,
    accuracy_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN planned_reps > 0
            THEN ROUND((actual_reps::DECIMAL / planned_reps * 100), 2)
            ELSE 100.00
        END
    ) STORED,

    -- Additional context
    weight_kg DECIMAL(6,2),
    was_modified BOOLEAN DEFAULT FALSE,
    modification_reason TEXT CHECK (
        modification_reason IS NULL OR modification_reason IN (
            'fatigue',
            'too_easy',
            'pain',
            'form_breakdown',
            'time_constraint',
            'equipment_issue',
            'personal_best',
            'other'
        )
    ),
    modification_notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure unique set tracking per exercise per workout log
    UNIQUE(workout_log_id, exercise_index, set_number)
);

-- Add table-level comment
COMMENT ON TABLE set_rep_accuracy IS 'Tracks actual vs planned reps for each set to enable accurate workout history and AI learning. Addresses user feedback about inability to record actual completed reps.';

-- Column-level comments
COMMENT ON COLUMN set_rep_accuracy.exercise_index IS 'Position of the exercise within the workout (0-indexed)';
COMMENT ON COLUMN set_rep_accuracy.exercise_id IS 'Optional reference to exercise library ID';
COMMENT ON COLUMN set_rep_accuracy.set_number IS 'The set number within the exercise (1-indexed)';
COMMENT ON COLUMN set_rep_accuracy.planned_reps IS 'Number of reps prescribed in the workout plan';
COMMENT ON COLUMN set_rep_accuracy.actual_reps IS 'Number of reps actually completed by the user';
COMMENT ON COLUMN set_rep_accuracy.rep_difference IS 'Computed: actual_reps - planned_reps (positive = exceeded target, negative = fell short)';
COMMENT ON COLUMN set_rep_accuracy.accuracy_percentage IS 'Computed: percentage of planned reps completed';
COMMENT ON COLUMN set_rep_accuracy.was_modified IS 'Whether the user manually modified the rep count from the planned value';
COMMENT ON COLUMN set_rep_accuracy.modification_reason IS 'User-provided reason for the rep modification';
COMMENT ON COLUMN set_rep_accuracy.modification_notes IS 'Additional user notes about why reps were modified';

-- ============================================================================
-- 2. CREATE INDEXES
-- ============================================================================

-- Primary query index: user lookups with time-based filtering
CREATE INDEX IF NOT EXISTS idx_set_rep_accuracy_user_created
    ON set_rep_accuracy(user_id, created_at DESC);

-- Index for workout log associations
CREATE INDEX IF NOT EXISTS idx_set_rep_accuracy_workout_log
    ON set_rep_accuracy(workout_log_id);

-- Index for exercise-specific pattern analysis
CREATE INDEX IF NOT EXISTS idx_set_rep_accuracy_exercise_name
    ON set_rep_accuracy(exercise_name);

-- Index for finding modified sets
CREATE INDEX IF NOT EXISTS idx_set_rep_accuracy_modified
    ON set_rep_accuracy(was_modified) WHERE was_modified = TRUE;

-- Index for accuracy analysis (find sets where users consistently fall short)
CREATE INDEX IF NOT EXISTS idx_set_rep_accuracy_below_target
    ON set_rep_accuracy(user_id, exercise_name, accuracy_percentage)
    WHERE accuracy_percentage < 100;

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE set_rep_accuracy ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. RLS POLICIES
-- ============================================================================

-- Policy: Users can only view their own rep accuracy data
DROP POLICY IF EXISTS "Users can view own rep accuracy" ON set_rep_accuracy;
CREATE POLICY "Users can view own rep accuracy"
    ON set_rep_accuracy
    FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Policy: Users can insert their own rep accuracy data
DROP POLICY IF EXISTS "Users can insert own rep accuracy" ON set_rep_accuracy;
CREATE POLICY "Users can insert own rep accuracy"
    ON set_rep_accuracy
    FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Policy: Users can update their own rep accuracy data
DROP POLICY IF EXISTS "Users can update own rep accuracy" ON set_rep_accuracy;
CREATE POLICY "Users can update own rep accuracy"
    ON set_rep_accuracy
    FOR UPDATE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Policy: Users can delete their own rep accuracy data
DROP POLICY IF EXISTS "Users can delete own rep accuracy" ON set_rep_accuracy;
CREATE POLICY "Users can delete own rep accuracy"
    ON set_rep_accuracy
    FOR DELETE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Policy: Service role can manage all rep accuracy data
DROP POLICY IF EXISTS "Service role can manage all rep accuracy" ON set_rep_accuracy;
CREATE POLICY "Service role can manage all rep accuracy"
    ON set_rep_accuracy
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- 5. CREATE ANALYTICS VIEW: v_user_rep_accuracy_patterns
-- ============================================================================

CREATE OR REPLACE VIEW v_user_rep_accuracy_patterns
WITH (security_invoker = true)
AS
SELECT
    user_id,
    exercise_name,
    COUNT(*) AS total_sets_tracked,
    ROUND(AVG(accuracy_percentage), 1) AS avg_accuracy_percentage,
    ROUND(AVG(rep_difference), 1) AS avg_rep_difference,
    SUM(CASE WHEN actual_reps >= planned_reps THEN 1 ELSE 0 END) AS sets_met_target,
    SUM(CASE WHEN actual_reps < planned_reps THEN 1 ELSE 0 END) AS sets_below_target,
    SUM(CASE WHEN actual_reps > planned_reps THEN 1 ELSE 0 END) AS sets_exceeded_target,
    SUM(CASE WHEN was_modified THEN 1 ELSE 0 END) AS sets_manually_modified,
    MODE() WITHIN GROUP (ORDER BY modification_reason) AS most_common_modification_reason,
    MIN(created_at) AS first_tracked,
    MAX(created_at) AS last_tracked
FROM set_rep_accuracy
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY user_id, exercise_name;

-- Add comment for view
COMMENT ON VIEW v_user_rep_accuracy_patterns IS 'Analytics view showing user rep accuracy patterns per exercise over the last 30 days. Helps identify exercises where users consistently fall short or exceed targets.';

-- ============================================================================
-- 6. CREATE SUMMARY VIEW: v_user_rep_accuracy_summary
-- Provides overall user-level accuracy metrics
-- ============================================================================

CREATE OR REPLACE VIEW v_user_rep_accuracy_summary
WITH (security_invoker = true)
AS
WITH user_stats AS (
    SELECT
        user_id,
        COUNT(*) AS total_sets,
        SUM(planned_reps) AS total_planned_reps,
        SUM(actual_reps) AS total_actual_reps,
        ROUND(AVG(accuracy_percentage), 1) AS overall_accuracy_percentage,
        SUM(CASE WHEN actual_reps >= planned_reps THEN 1 ELSE 0 END) AS sets_met_or_exceeded,
        SUM(CASE WHEN actual_reps < planned_reps THEN 1 ELSE 0 END) AS sets_below_target,
        SUM(CASE WHEN was_modified THEN 1 ELSE 0 END) AS sets_modified,
        COUNT(DISTINCT workout_log_id) AS workouts_tracked,
        COUNT(DISTINCT exercise_name) AS exercises_tracked
    FROM set_rep_accuracy
    WHERE created_at >= NOW() - INTERVAL '30 days'
    GROUP BY user_id
),
exercises_needing_adjustment AS (
    -- Find exercises where user consistently falls short (< 80% accuracy over multiple sets)
    SELECT
        user_id,
        JSONB_AGG(
            JSONB_BUILD_OBJECT(
                'exercise_name', exercise_name,
                'avg_accuracy', avg_accuracy_percentage,
                'sets_tracked', total_sets_tracked
            ) ORDER BY avg_accuracy_percentage ASC
        ) AS exercises_below_target
    FROM v_user_rep_accuracy_patterns
    WHERE avg_accuracy_percentage < 80 AND total_sets_tracked >= 3
    GROUP BY user_id
)
SELECT
    us.user_id,
    us.total_sets,
    us.total_planned_reps,
    us.total_actual_reps,
    us.overall_accuracy_percentage,
    us.sets_met_or_exceeded,
    us.sets_below_target,
    us.sets_modified,
    us.workouts_tracked,
    us.exercises_tracked,
    ROUND((us.sets_met_or_exceeded::DECIMAL / NULLIF(us.total_sets, 0)) * 100, 1) AS target_hit_rate,
    ROUND((us.sets_modified::DECIMAL / NULLIF(us.total_sets, 0)) * 100, 1) AS modification_rate,
    COALESCE(ena.exercises_below_target, '[]'::JSONB) AS exercises_needing_easier_targets
FROM user_stats us
LEFT JOIN exercises_needing_adjustment ena ON us.user_id = ena.user_id;

-- Add comment for summary view
COMMENT ON VIEW v_user_rep_accuracy_summary IS 'User-level summary of rep accuracy metrics over the last 30 days. Includes identification of exercises that may need easier targets.';

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

-- Grant access to authenticated users via API
GRANT SELECT, INSERT, UPDATE, DELETE ON set_rep_accuracy TO authenticated;
GRANT SELECT ON v_user_rep_accuracy_patterns TO authenticated;
GRANT SELECT ON v_user_rep_accuracy_summary TO authenticated;

-- Grant usage to anon for public access patterns if needed
GRANT SELECT ON set_rep_accuracy TO anon;
GRANT SELECT ON v_user_rep_accuracy_patterns TO anon;
GRANT SELECT ON v_user_rep_accuracy_summary TO anon;

-- ============================================================================
-- 8. DOCUMENTATION
-- ============================================================================

-- Final table-level documentation
COMMENT ON TABLE set_rep_accuracy IS
'Tracks actual vs planned reps for each set to enable accurate workout history and AI learning.

This table was created to address user feedback: "it told me to do 50 crunches... I could
only do 30 crunches but there was no option to input this anywhere so now it says I did
50 crunches when I didn''t"

Key features:
- Per-set tracking of planned vs actual reps
- Automatic calculation of accuracy percentage and difference
- Modification reasons for understanding why users fall short
- Analytics views for identifying exercises that need easier targets

Usage:
1. When user completes a set, record planned_reps and actual_reps
2. If actual differs from planned, set was_modified = true and capture reason
3. Use v_user_rep_accuracy_patterns to identify exercises needing adjustment
4. Use v_user_rep_accuracy_summary for overall user rep accuracy metrics';
