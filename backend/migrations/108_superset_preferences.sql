-- Migration: 108_superset_preferences.sql
-- Description: Superset preferences system for AI-generated workout supersets
-- Created: 2025-12-30

-- ============================================================================
-- 1. SUPERSET_PREFERENCES TABLE
-- ============================================================================
-- Stores user preferences for superset generation

CREATE TABLE IF NOT EXISTS superset_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    supersets_enabled BOOLEAN NOT NULL DEFAULT true,
    prefer_antagonist_pairs BOOLEAN NOT NULL DEFAULT true,
    prefer_compound_sets BOOLEAN NOT NULL DEFAULT false,
    max_superset_pairs INTEGER NOT NULL DEFAULT 3 CHECK (max_superset_pairs >= 0 AND max_superset_pairs <= 10),
    superset_rest_seconds INTEGER NOT NULL DEFAULT 0 CHECK (superset_rest_seconds >= 0 AND superset_rest_seconds <= 300),
    post_superset_rest_seconds INTEGER NOT NULL DEFAULT 90 CHECK (post_superset_rest_seconds >= 0 AND post_superset_rest_seconds <= 600),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT superset_preferences_user_id_unique UNIQUE (user_id)
);

-- Add comment for documentation
COMMENT ON TABLE superset_preferences IS 'User preferences for AI-generated workout supersets';
COMMENT ON COLUMN superset_preferences.supersets_enabled IS 'Whether to auto-generate supersets in workouts';
COMMENT ON COLUMN superset_preferences.prefer_antagonist_pairs IS 'Prefer antagonist muscle pairs (chest/back, biceps/triceps)';
COMMENT ON COLUMN superset_preferences.prefer_compound_sets IS 'Prefer compound sets (same muscle group pairs)';
COMMENT ON COLUMN superset_preferences.max_superset_pairs IS 'Maximum number of superset pairs per workout';
COMMENT ON COLUMN superset_preferences.superset_rest_seconds IS 'Rest time between exercises within a superset';
COMMENT ON COLUMN superset_preferences.post_superset_rest_seconds IS 'Rest time after completing a full superset pair';

-- ============================================================================
-- 2. USER_SUPERSET_HISTORY TABLE
-- ============================================================================
-- Tracks which supersets user has performed for analytics and recommendations

CREATE TABLE IF NOT EXISTS user_superset_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    exercise_1_name TEXT NOT NULL,
    exercise_2_name TEXT NOT NULL,
    superset_type TEXT NOT NULL CHECK (superset_type IN ('antagonist', 'compound', 'pre_exhaust', 'custom')),
    times_completed INTEGER NOT NULL DEFAULT 0 CHECK (times_completed >= 0),
    avg_rating NUMERIC(3, 2) CHECK (avg_rating IS NULL OR (avg_rating >= 1.00 AND avg_rating <= 5.00)),
    last_used_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add comment for documentation
COMMENT ON TABLE user_superset_history IS 'History of supersets performed by users for analytics';
COMMENT ON COLUMN user_superset_history.superset_type IS 'Type of superset: antagonist, compound, pre_exhaust, or custom';
COMMENT ON COLUMN user_superset_history.times_completed IS 'Number of times this superset pair has been completed';
COMMENT ON COLUMN user_superset_history.avg_rating IS 'User average rating for this superset pair (1.00-5.00)';

-- ============================================================================
-- 3. FAVORITE_SUPERSET_PAIRS TABLE
-- ============================================================================
-- User-saved favorite superset combinations

CREATE TABLE IF NOT EXISTS favorite_superset_pairs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_1_name TEXT NOT NULL,
    exercise_2_name TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CONSTRAINT favorite_superset_pairs_unique UNIQUE (user_id, exercise_1_name, exercise_2_name)
);

-- Add comment for documentation
COMMENT ON TABLE favorite_superset_pairs IS 'User-saved favorite superset exercise combinations';
COMMENT ON COLUMN favorite_superset_pairs.notes IS 'Optional user notes about this superset pair';

-- ============================================================================
-- 4. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for superset_preferences lookup by user
CREATE INDEX IF NOT EXISTS idx_superset_preferences_user_id
    ON superset_preferences(user_id);

-- Index for user_superset_history queries by user and recency
CREATE INDEX IF NOT EXISTS idx_user_superset_history_user_id_last_used
    ON user_superset_history(user_id, last_used_at DESC);

-- Index for user_superset_history by workout for cascade operations
CREATE INDEX IF NOT EXISTS idx_user_superset_history_workout_id
    ON user_superset_history(workout_id)
    WHERE workout_id IS NOT NULL;

-- Index for favorite_superset_pairs lookup by user
CREATE INDEX IF NOT EXISTS idx_favorite_superset_pairs_user_id
    ON favorite_superset_pairs(user_id);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE superset_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_superset_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_superset_pairs ENABLE ROW LEVEL SECURITY;

-- -------------------------
-- superset_preferences RLS
-- -------------------------

-- Users can view their own preferences
CREATE POLICY "Users can view own superset preferences"
    ON superset_preferences FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can create own superset preferences"
    ON superset_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own superset preferences"
    ON superset_preferences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own preferences
CREATE POLICY "Users can delete own superset preferences"
    ON superset_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- -------------------------
-- user_superset_history RLS
-- -------------------------

-- Users can view their own history
CREATE POLICY "Users can view own superset history"
    ON user_superset_history FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own history
CREATE POLICY "Users can create own superset history"
    ON user_superset_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own history
CREATE POLICY "Users can update own superset history"
    ON user_superset_history FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own history
CREATE POLICY "Users can delete own superset history"
    ON user_superset_history FOR DELETE
    USING (auth.uid() = user_id);

-- -------------------------
-- favorite_superset_pairs RLS
-- -------------------------

-- Users can view their own favorites
CREATE POLICY "Users can view own favorite supersets"
    ON favorite_superset_pairs FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own favorites
CREATE POLICY "Users can create own favorite supersets"
    ON favorite_superset_pairs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own favorites
CREATE POLICY "Users can update own favorite supersets"
    ON favorite_superset_pairs FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own favorites
CREATE POLICY "Users can delete own favorite supersets"
    ON favorite_superset_pairs FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 6. UPDATED_AT TRIGGER
-- ============================================================================

-- Create trigger function if not exists
CREATE OR REPLACE FUNCTION update_superset_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for superset_preferences
DROP TRIGGER IF EXISTS trigger_superset_preferences_updated_at ON superset_preferences;
CREATE TRIGGER trigger_superset_preferences_updated_at
    BEFORE UPDATE ON superset_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_superset_preferences_updated_at();

-- ============================================================================
-- 7. SUPERSET_ANALYTICS VIEW
-- ============================================================================
-- Aggregated analytics view for superset usage per user

CREATE OR REPLACE VIEW superset_analytics AS
WITH user_stats AS (
    SELECT
        user_id,
        COUNT(*) AS total_superset_records,
        SUM(times_completed) AS total_supersets_completed,
        AVG(avg_rating) FILTER (WHERE avg_rating IS NOT NULL) AS overall_avg_rating,
        MAX(last_used_at) AS last_superset_date
    FROM user_superset_history
    GROUP BY user_id
),
most_used AS (
    SELECT DISTINCT ON (user_id)
        user_id,
        exercise_1_name || ' + ' || exercise_2_name AS most_used_pair,
        times_completed AS most_used_count
    FROM user_superset_history
    ORDER BY user_id, times_completed DESC, last_used_at DESC
),
preference_summary AS (
    SELECT
        user_id,
        CASE
            WHEN NOT supersets_enabled THEN 'disabled'
            WHEN prefer_antagonist_pairs AND prefer_compound_sets THEN 'mixed'
            WHEN prefer_antagonist_pairs THEN 'antagonist-focused'
            WHEN prefer_compound_sets THEN 'compound-focused'
            ELSE 'standard'
        END AS preference_type,
        max_superset_pairs,
        superset_rest_seconds,
        post_superset_rest_seconds
    FROM superset_preferences
)
SELECT
    COALESCE(us.user_id, mu.user_id, ps.user_id) AS user_id,
    COALESCE(us.total_supersets_completed, 0) AS total_supersets_completed,
    mu.most_used_pair,
    ROUND(us.overall_avg_rating, 2) AS avg_rating,
    us.last_superset_date,
    COALESCE(ps.preference_type, 'default') AS preference_type,
    COALESCE(ps.max_superset_pairs, 3) AS max_superset_pairs,
    jsonb_build_object(
        'enabled', COALESCE((SELECT supersets_enabled FROM superset_preferences WHERE user_id = COALESCE(us.user_id, mu.user_id, ps.user_id)), true),
        'antagonist_pairs', COALESCE((SELECT prefer_antagonist_pairs FROM superset_preferences WHERE user_id = COALESCE(us.user_id, mu.user_id, ps.user_id)), true),
        'compound_sets', COALESCE((SELECT prefer_compound_sets FROM superset_preferences WHERE user_id = COALESCE(us.user_id, mu.user_id, ps.user_id)), false),
        'rest_between', COALESCE(ps.superset_rest_seconds, 0),
        'rest_after', COALESCE(ps.post_superset_rest_seconds, 90)
    ) AS preference_summary
FROM user_stats us
FULL OUTER JOIN most_used mu ON us.user_id = mu.user_id
FULL OUTER JOIN preference_summary ps ON COALESCE(us.user_id, mu.user_id) = ps.user_id;

-- Add comment for view documentation
COMMENT ON VIEW superset_analytics IS 'Aggregated superset analytics per user including preferences and usage stats';

-- ============================================================================
-- 8. HELPER FUNCTION FOR UPSERT
-- ============================================================================
-- Function to upsert superset preferences

CREATE OR REPLACE FUNCTION upsert_superset_preferences(
    p_user_id UUID,
    p_supersets_enabled BOOLEAN DEFAULT true,
    p_prefer_antagonist_pairs BOOLEAN DEFAULT true,
    p_prefer_compound_sets BOOLEAN DEFAULT false,
    p_max_superset_pairs INTEGER DEFAULT 3,
    p_superset_rest_seconds INTEGER DEFAULT 0,
    p_post_superset_rest_seconds INTEGER DEFAULT 90
)
RETURNS superset_preferences AS $$
DECLARE
    result superset_preferences;
BEGIN
    INSERT INTO superset_preferences (
        user_id,
        supersets_enabled,
        prefer_antagonist_pairs,
        prefer_compound_sets,
        max_superset_pairs,
        superset_rest_seconds,
        post_superset_rest_seconds
    ) VALUES (
        p_user_id,
        p_supersets_enabled,
        p_prefer_antagonist_pairs,
        p_prefer_compound_sets,
        p_max_superset_pairs,
        p_superset_rest_seconds,
        p_post_superset_rest_seconds
    )
    ON CONFLICT (user_id) DO UPDATE SET
        supersets_enabled = EXCLUDED.supersets_enabled,
        prefer_antagonist_pairs = EXCLUDED.prefer_antagonist_pairs,
        prefer_compound_sets = EXCLUDED.prefer_compound_sets,
        max_superset_pairs = EXCLUDED.max_superset_pairs,
        superset_rest_seconds = EXCLUDED.superset_rest_seconds,
        post_superset_rest_seconds = EXCLUDED.post_superset_rest_seconds,
        updated_at = now()
    RETURNING * INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION upsert_superset_preferences TO authenticated;

-- ============================================================================
-- 9. FUNCTION TO RECORD SUPERSET COMPLETION
-- ============================================================================

CREATE OR REPLACE FUNCTION record_superset_completion(
    p_user_id UUID,
    p_workout_id UUID,
    p_exercise_1_name TEXT,
    p_exercise_2_name TEXT,
    p_superset_type TEXT,
    p_rating NUMERIC DEFAULT NULL
)
RETURNS user_superset_history AS $$
DECLARE
    existing_record user_superset_history;
    result user_superset_history;
BEGIN
    -- Check if this superset pair already exists for the user
    SELECT * INTO existing_record
    FROM user_superset_history
    WHERE user_id = p_user_id
      AND exercise_1_name = p_exercise_1_name
      AND exercise_2_name = p_exercise_2_name;

    IF existing_record IS NOT NULL THEN
        -- Update existing record
        UPDATE user_superset_history
        SET
            times_completed = times_completed + 1,
            avg_rating = CASE
                WHEN p_rating IS NOT NULL THEN
                    COALESCE((avg_rating * times_completed + p_rating) / (times_completed + 1), p_rating)
                ELSE avg_rating
            END,
            last_used_at = now(),
            workout_id = COALESCE(p_workout_id, workout_id)
        WHERE id = existing_record.id
        RETURNING * INTO result;
    ELSE
        -- Insert new record
        INSERT INTO user_superset_history (
            user_id,
            workout_id,
            exercise_1_name,
            exercise_2_name,
            superset_type,
            times_completed,
            avg_rating,
            last_used_at
        ) VALUES (
            p_user_id,
            p_workout_id,
            p_exercise_1_name,
            p_exercise_2_name,
            p_superset_type,
            1,
            p_rating,
            now()
        )
        RETURNING * INTO result;
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION record_superset_completion TO authenticated;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
