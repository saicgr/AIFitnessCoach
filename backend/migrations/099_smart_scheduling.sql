-- Smart Rescheduling Migration
-- Adds status tracking for missed, skipped, and rescheduled workouts
-- Enables intelligent rescheduling suggestions based on user behavior

-- ============================================
-- Add status tracking to workouts table
-- ============================================

-- Add workout status column if not exists
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'scheduled'
  CHECK (status IN ('scheduled', 'completed', 'missed', 'skipped', 'rescheduled'));

-- Add original date for rescheduled workouts
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS original_scheduled_date DATE;

-- Track how many times a workout has been rescheduled
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS reschedule_count INTEGER DEFAULT 0;

-- Store skip reason when user intentionally skips
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS skip_reason TEXT;

-- Store rescheduled from workout id (if this workout was rescheduled from another)
ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS rescheduled_from_workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL;

-- ============================================
-- Create scheduling history table
-- ============================================

-- Track all scheduling actions for analytics and AI learning
CREATE TABLE IF NOT EXISTS workout_scheduling_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,

    -- Action taken
    action_type VARCHAR(20) NOT NULL
      CHECK (action_type IN ('reschedule', 'skip', 'restore', 'auto_missed')),

    -- Dates involved
    original_date DATE NOT NULL,
    new_date DATE,  -- NULL for skip actions

    -- Context
    reason TEXT,  -- User-provided reason or system reason
    reason_category VARCHAR(50),  -- 'too_busy', 'feeling_unwell', 'need_rest', 'travel', 'other'

    -- Swap context (when rescheduling replaces another workout)
    swapped_workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    swapped_workout_name VARCHAR(200),

    -- AI suggestion context
    was_ai_suggested BOOLEAN DEFAULT FALSE,
    ai_suggestion_reason TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- For tracking patterns
    day_of_week INTEGER,  -- 0=Monday, 6=Sunday
    week_number INTEGER
);

-- Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_scheduling_history_user_id
    ON workout_scheduling_history(user_id);
CREATE INDEX IF NOT EXISTS idx_scheduling_history_workout_id
    ON workout_scheduling_history(workout_id);
CREATE INDEX IF NOT EXISTS idx_scheduling_history_action_date
    ON workout_scheduling_history(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_scheduling_history_reason_category
    ON workout_scheduling_history(user_id, reason_category);

-- Create index on workouts for status-based queries
CREATE INDEX IF NOT EXISTS idx_workouts_status
    ON workouts(user_id, status, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_workouts_missed
    ON workouts(user_id, status, scheduled_date)
    WHERE status = 'missed';

-- ============================================
-- Create skip reason reference table
-- ============================================

CREATE TABLE IF NOT EXISTS skip_reason_categories (
    id VARCHAR(50) PRIMARY KEY,
    display_name VARCHAR(100) NOT NULL,
    emoji VARCHAR(10),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert default skip reasons
INSERT INTO skip_reason_categories (id, display_name, emoji, sort_order) VALUES
    ('too_busy', 'Too Busy', '📅', 1),
    ('feeling_unwell', 'Feeling Unwell', '🤒', 2),
    ('need_rest', 'Need Rest', '😴', 3),
    ('travel', 'Traveling', '✈️', 4),
    ('injury', 'Injury/Pain', '🤕', 5),
    ('other', 'Other', '💭', 10)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- User scheduling preferences
-- ============================================

CREATE TABLE IF NOT EXISTS user_scheduling_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    -- Auto-detection settings
    auto_detect_missed BOOLEAN DEFAULT TRUE,  -- Automatically mark as missed after 11:59pm
    missed_notification_enabled BOOLEAN DEFAULT TRUE,  -- Send notification for missed workouts

    -- Rescheduling preferences
    max_reschedule_days INTEGER DEFAULT 3,  -- How many days in advance can reschedule
    allow_same_day_swap BOOLEAN DEFAULT TRUE,  -- Can swap with today's workout
    prefer_swap_similar_type BOOLEAN DEFAULT TRUE,  -- Prefer swapping with similar workout type

    -- Skip tracking
    track_skip_patterns BOOLEAN DEFAULT TRUE,  -- Use skip patterns for AI suggestions

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_scheduling_prefs_user_id
    ON user_scheduling_preferences(user_id);

-- ============================================
-- Function to auto-mark missed workouts
-- ============================================

-- This function should be called by a cron job or on user login
CREATE OR REPLACE FUNCTION mark_missed_workouts(p_user_id UUID DEFAULT NULL)
RETURNS INTEGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    missed_count INTEGER;
BEGIN
    -- Mark workouts as missed if:
    -- 1. scheduled_date is before today (in user's timezone, but we use UTC for simplicity)
    -- 2. status is still 'scheduled'
    -- 3. is_completed is false

    WITH updated AS (
        UPDATE workouts
        SET
            status = 'missed',
            last_modified_at = NOW(),
            last_modified_method = 'auto_missed'
        WHERE
            scheduled_date::date < CURRENT_DATE
            AND status = 'scheduled'
            AND is_completed = FALSE
            AND (p_user_id IS NULL OR user_id = p_user_id)
        RETURNING id, user_id, scheduled_date
    )
    SELECT COUNT(*) INTO missed_count FROM updated;

    -- Log the missed workouts to scheduling history
    INSERT INTO workout_scheduling_history (
        user_id, workout_id, action_type, original_date, reason,
        day_of_week, week_number
    )
    SELECT
        user_id,
        id,
        'auto_missed',
        scheduled_date::date,
        'Automatically marked as missed (workout date passed)',
        EXTRACT(DOW FROM scheduled_date)::INTEGER,
        EXTRACT(WEEK FROM scheduled_date)::INTEGER
    FROM (
        SELECT id, user_id, scheduled_date
        FROM workouts
        WHERE
            last_modified_method = 'auto_missed'
            AND last_modified_at >= NOW() - INTERVAL '1 minute'
            AND (p_user_id IS NULL OR user_id = p_user_id)
    ) just_missed;

    RETURN missed_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Function to reschedule a workout
-- ============================================

CREATE OR REPLACE FUNCTION reschedule_workout(
    p_workout_id UUID,
    p_new_date DATE,
    p_swap_with_workout_id UUID DEFAULT NULL,
    p_reason TEXT DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_workout RECORD;
    v_swap_workout RECORD;
    v_result JSON;
BEGIN
    -- Get the workout to reschedule
    SELECT * INTO v_workout
    FROM workouts
    WHERE id = p_workout_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Workout not found'
        );
    END IF;

    -- Check if workout can be rescheduled (not completed)
    IF v_workout.is_completed THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot reschedule a completed workout'
        );
    END IF;

    -- If swapping with another workout
    IF p_swap_with_workout_id IS NOT NULL THEN
        SELECT * INTO v_swap_workout
        FROM workouts
        WHERE id = p_swap_with_workout_id;

        IF NOT FOUND THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Swap workout not found'
            );
        END IF;

        -- Swap the dates
        UPDATE workouts
        SET scheduled_date = v_workout.scheduled_date,
            last_modified_at = NOW(),
            last_modified_method = 'reschedule_swap'
        WHERE id = p_swap_with_workout_id;
    END IF;

    -- Update the main workout
    UPDATE workouts
    SET
        scheduled_date = p_new_date,
        original_scheduled_date = COALESCE(original_scheduled_date, v_workout.scheduled_date::date),
        status = 'rescheduled',
        reschedule_count = reschedule_count + 1,
        last_modified_at = NOW(),
        last_modified_method = 'user_reschedule'
    WHERE id = p_workout_id;

    -- Log the action
    INSERT INTO workout_scheduling_history (
        user_id, workout_id, action_type, original_date, new_date,
        reason, swapped_workout_id, swapped_workout_name,
        day_of_week, week_number
    ) VALUES (
        v_workout.user_id,
        p_workout_id,
        'reschedule',
        v_workout.scheduled_date::date,
        p_new_date,
        p_reason,
        p_swap_with_workout_id,
        v_swap_workout.name,
        EXTRACT(DOW FROM v_workout.scheduled_date)::INTEGER,
        EXTRACT(WEEK FROM v_workout.scheduled_date)::INTEGER
    );

    RETURN json_build_object(
        'success', true,
        'workout_id', p_workout_id,
        'new_date', p_new_date,
        'swapped_with', p_swap_with_workout_id
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Function to skip a workout
-- ============================================

CREATE OR REPLACE FUNCTION skip_workout(
    p_workout_id UUID,
    p_reason_category VARCHAR(50) DEFAULT NULL,
    p_reason_text TEXT DEFAULT NULL
)
RETURNS JSON
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_workout RECORD;
BEGIN
    -- Get the workout
    SELECT * INTO v_workout
    FROM workouts
    WHERE id = p_workout_id;

    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Workout not found'
        );
    END IF;

    -- Check if workout can be skipped (not completed)
    IF v_workout.is_completed THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Cannot skip a completed workout'
        );
    END IF;

    -- Update the workout
    UPDATE workouts
    SET
        status = 'skipped',
        skip_reason = COALESCE(p_reason_text, p_reason_category),
        last_modified_at = NOW(),
        last_modified_method = 'user_skip'
    WHERE id = p_workout_id;

    -- Log the action
    INSERT INTO workout_scheduling_history (
        user_id, workout_id, action_type, original_date,
        reason, reason_category,
        day_of_week, week_number
    ) VALUES (
        v_workout.user_id,
        p_workout_id,
        'skip',
        v_workout.scheduled_date::date,
        p_reason_text,
        p_reason_category,
        EXTRACT(DOW FROM v_workout.scheduled_date)::INTEGER,
        EXTRACT(WEEK FROM v_workout.scheduled_date)::INTEGER
    );

    RETURN json_build_object(
        'success', true,
        'workout_id', p_workout_id,
        'status', 'skipped'
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- View for missed workouts (recent)
-- ============================================

CREATE OR REPLACE VIEW v_recent_missed_workouts AS
SELECT
    w.id,
    w.user_id,
    w.name,
    w.type,
    w.difficulty,
    w.scheduled_date,
    w.status,
    w.original_scheduled_date,
    w.reschedule_count,
    w.duration_minutes,
    w.exercises_json,
    -- Days since missed
    (CURRENT_DATE - w.scheduled_date::date) AS days_missed,
    -- Can still reschedule (within 7 days)
    (CURRENT_DATE - w.scheduled_date::date) <= 7 AS can_reschedule
FROM workouts w
WHERE
    w.status IN ('missed', 'scheduled')
    AND w.is_completed = FALSE
    AND w.scheduled_date::date < CURRENT_DATE
    AND w.scheduled_date::date >= (CURRENT_DATE - INTERVAL '7 days')
ORDER BY w.scheduled_date DESC;

-- Grant access
GRANT SELECT ON v_recent_missed_workouts TO authenticated;

-- ============================================
-- View for user scheduling patterns
-- ============================================

CREATE OR REPLACE VIEW v_user_scheduling_patterns AS
SELECT
    user_id,
    reason_category,
    COUNT(*) as skip_count,
    EXTRACT(DOW FROM created_at) as day_of_week,
    COUNT(*) FILTER (WHERE action_type = 'skip') as skips,
    COUNT(*) FILTER (WHERE action_type = 'reschedule') as reschedules,
    COUNT(*) FILTER (WHERE action_type = 'auto_missed') as auto_missed
FROM workout_scheduling_history
WHERE created_at >= NOW() - INTERVAL '90 days'
GROUP BY user_id, reason_category, EXTRACT(DOW FROM created_at);

GRANT SELECT ON v_user_scheduling_patterns TO authenticated;

-- ============================================
-- Enable RLS
-- ============================================

ALTER TABLE workout_scheduling_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_scheduling_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE skip_reason_categories ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workout_scheduling_history
CREATE POLICY "Users can view own scheduling history"
    ON workout_scheduling_history FOR SELECT
    USING (user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Users can insert own scheduling history"
    ON workout_scheduling_history FOR INSERT
    WITH CHECK (user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
    ));

-- RLS Policies for user_scheduling_preferences
CREATE POLICY "Users can view own scheduling preferences"
    ON user_scheduling_preferences FOR SELECT
    USING (user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Users can manage own scheduling preferences"
    ON user_scheduling_preferences FOR ALL
    USING (user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
    ));

-- RLS Policies for skip_reason_categories (read-only for all)
CREATE POLICY "Anyone can read skip reason categories"
    ON skip_reason_categories FOR SELECT
    USING (is_active = TRUE);

-- ============================================
-- Update existing workouts - set status based on is_completed
-- ============================================

-- Mark completed workouts
UPDATE workouts
SET status = 'completed'
WHERE is_completed = TRUE AND status = 'scheduled';

-- Don't auto-mark as missed here - let the function handle it on first query
