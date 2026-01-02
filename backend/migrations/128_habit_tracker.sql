-- Migration: 128_habit_tracker.sql
-- Description: Habit Tracking System for daily habit monitoring and streak tracking
-- Created: 2026-01-01

-- ============================================================================
-- HABITS TABLE (Master table for habit definitions)
-- ============================================================================
-- Stores user-defined and AI-suggested habits with customizable settings

CREATE TABLE IF NOT EXISTS habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Habit details
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'general' CHECK (category IN (
        'nutrition', 'activity', 'health', 'lifestyle', 'general'
    )),
    habit_type TEXT NOT NULL DEFAULT 'positive' CHECK (habit_type IN (
        'positive',  -- Do something (e.g., "Walk 10k steps")
        'negative'   -- Avoid something (e.g., "No eating outside")
    )),

    -- Frequency settings
    frequency TEXT NOT NULL DEFAULT 'daily' CHECK (frequency IN (
        'daily',         -- Every day
        'weekly',        -- X times per week
        'specific_days'  -- Only on specific days
    )),
    target_days INTEGER[] DEFAULT NULL,  -- For specific_days: 0=Sunday, 6=Saturday

    -- Quantitative tracking
    target_count INTEGER DEFAULT 1,  -- e.g., 10000 for steps, 8 for glasses of water
    unit TEXT DEFAULT NULL,  -- e.g., 'steps', 'glasses', 'minutes', 'times'

    -- Display settings
    icon TEXT DEFAULT 'check_circle',  -- Icon name for UI display
    color TEXT DEFAULT '#4CAF50',  -- Hex color code

    -- Reminder settings
    reminder_time TIME DEFAULT NULL,  -- Optional reminder time
    reminder_enabled BOOLEAN DEFAULT FALSE,

    -- Status flags
    is_active BOOLEAN DEFAULT TRUE,  -- Whether habit is currently tracked
    is_suggested BOOLEAN DEFAULT FALSE,  -- AI suggested habit

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for habits
CREATE INDEX IF NOT EXISTS idx_habits_user_active ON habits(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_habits_user_category ON habits(user_id, category);
CREATE INDEX IF NOT EXISTS idx_habits_created_at ON habits(created_at DESC);

-- ============================================================================
-- HABIT_LOGS TABLE (Daily habit completion logs)
-- ============================================================================
-- Tracks daily completion status for each habit

CREATE TABLE IF NOT EXISTS habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Log date (one entry per habit per day)
    log_date DATE NOT NULL,

    -- Completion status
    completed BOOLEAN DEFAULT FALSE,
    value NUMERIC DEFAULT NULL,  -- For quantitative habits (e.g., 8500 steps)

    -- User notes
    notes TEXT DEFAULT NULL,

    -- Skip tracking
    skipped BOOLEAN DEFAULT FALSE,  -- User explicitly skipped
    skip_reason TEXT DEFAULT NULL,  -- Why they skipped

    -- Completion timestamp
    completed_at TIMESTAMPTZ DEFAULT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- One log per habit per day
    CONSTRAINT unique_habit_log_date UNIQUE (habit_id, log_date)
);

-- Indexes for habit_logs
CREATE INDEX IF NOT EXISTS idx_habit_logs_habit_date ON habit_logs(habit_id, log_date);
CREATE INDEX IF NOT EXISTS idx_habit_logs_user_date ON habit_logs(user_id, log_date);
CREATE INDEX IF NOT EXISTS idx_habit_logs_user_completed ON habit_logs(user_id, log_date, completed);
CREATE INDEX IF NOT EXISTS idx_habit_logs_created_at ON habit_logs(created_at DESC);

-- ============================================================================
-- HABIT_STREAKS TABLE (Streak tracking)
-- ============================================================================
-- Tracks current and longest streaks for each habit

CREATE TABLE IF NOT EXISTS habit_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Streak counts
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,

    -- Streak dates
    last_completed_date DATE DEFAULT NULL,
    streak_start_date DATE DEFAULT NULL,

    -- Timestamps
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- One streak record per habit
    CONSTRAINT unique_habit_streak UNIQUE (habit_id)
);

-- Indexes for habit_streaks
CREATE INDEX IF NOT EXISTS idx_habit_streaks_habit ON habit_streaks(habit_id);
CREATE INDEX IF NOT EXISTS idx_habit_streaks_user ON habit_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_habit_streaks_user_current ON habit_streaks(user_id, current_streak DESC);

-- ============================================================================
-- HABIT_TEMPLATES TABLE (Pre-defined habit templates)
-- ============================================================================
-- Provides suggested habits for users to quickly add

CREATE TABLE IF NOT EXISTS habit_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Template details
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN (
        'nutrition', 'activity', 'health', 'lifestyle', 'general'
    )),
    habit_type TEXT NOT NULL CHECK (habit_type IN ('positive', 'negative')),

    -- Suggested settings
    suggested_target INTEGER DEFAULT 1,
    unit TEXT DEFAULT NULL,

    -- Display settings
    icon TEXT DEFAULT 'check_circle',
    color TEXT DEFAULT '#4CAF50',

    -- Admin settings
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0
);

-- Index for habit_templates
CREATE INDEX IF NOT EXISTS idx_habit_templates_category ON habit_templates(category, sort_order);
CREATE INDEX IF NOT EXISTS idx_habit_templates_active ON habit_templates(is_active, sort_order);

-- ============================================================================
-- INSERT PRE-DEFINED HABIT TEMPLATES
-- ============================================================================

INSERT INTO habit_templates (name, description, category, habit_type, suggested_target, unit, icon, color, sort_order) VALUES
    -- Nutrition - Negative (Avoid)
    ('Not eating outside food', 'Avoid eating at restaurants or ordering takeout', 'nutrition', 'negative', 1, NULL, 'restaurant_menu', '#F44336', 1),
    ('No DoorDash/food delivery', 'Avoid ordering food through delivery apps', 'nutrition', 'negative', 1, NULL, 'delivery_dining', '#F44336', 2),
    ('No sugary drinks', 'Avoid soda, sweetened coffee, and sugary beverages', 'nutrition', 'negative', 1, NULL, 'no_drinks', '#F44336', 3),
    ('No late-night snacking', 'Stop eating after dinner or before bedtime', 'nutrition', 'negative', 1, NULL, 'nightlight', '#F44336', 4),

    -- Nutrition - Positive (Do)
    ('Eat healthy meals', 'Prepare and eat nutritious home-cooked meals', 'nutrition', 'positive', 3, 'meals', 'restaurant', '#4CAF50', 5),
    ('Cook at home', 'Prepare at least one meal at home', 'nutrition', 'positive', 1, 'meals', 'soup_kitchen', '#4CAF50', 6),
    ('Track all meals', 'Log all food and drinks consumed', 'nutrition', 'positive', 1, NULL, 'edit_note', '#4CAF50', 7),

    -- Activity - Positive
    ('Walk 10,000 steps', 'Reach daily step goal for active lifestyle', 'activity', 'positive', 10000, 'steps', 'directions_walk', '#2196F3', 10),
    ('Stretch/mobility work', 'Complete stretching or mobility exercises', 'activity', 'positive', 1, NULL, 'self_improvement', '#2196F3', 11),

    -- Health - Positive
    ('Drink 8 glasses of water', 'Stay hydrated throughout the day', 'health', 'positive', 8, 'glasses', 'water_drop', '#03A9F4', 20),
    ('Get 7+ hours sleep', 'Prioritize quality sleep each night', 'health', 'positive', 7, 'hours', 'bedtime', '#9C27B0', 21),
    ('Meditate', 'Practice mindfulness or meditation', 'health', 'positive', 1, NULL, 'self_improvement', '#9C27B0', 22),
    ('Take vitamins/supplements', 'Take daily vitamins and supplements', 'health', 'positive', 1, NULL, 'medication', '#4CAF50', 23),

    -- Health - Negative
    ('No alcohol', 'Avoid alcoholic beverages', 'health', 'negative', 1, NULL, 'no_drinks', '#F44336', 24),

    -- Lifestyle - Positive
    ('Read for 30 minutes', 'Dedicate time to reading books or articles', 'lifestyle', 'positive', 30, 'minutes', 'menu_book', '#FF9800', 30)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_templates ENABLE ROW LEVEL SECURITY;

-- Habits Policies - Users can only see/modify their own habits
DROP POLICY IF EXISTS habits_select_policy ON habits;
CREATE POLICY habits_select_policy ON habits
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habits_insert_policy ON habits;
CREATE POLICY habits_insert_policy ON habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habits_update_policy ON habits;
CREATE POLICY habits_update_policy ON habits
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habits_delete_policy ON habits;
CREATE POLICY habits_delete_policy ON habits
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habits_service_policy ON habits;
CREATE POLICY habits_service_policy ON habits
    FOR ALL USING (auth.role() = 'service_role');

-- Habit Logs Policies - Users can only see/modify their own logs
DROP POLICY IF EXISTS habit_logs_select_policy ON habit_logs;
CREATE POLICY habit_logs_select_policy ON habit_logs
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_logs_insert_policy ON habit_logs;
CREATE POLICY habit_logs_insert_policy ON habit_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_logs_update_policy ON habit_logs;
CREATE POLICY habit_logs_update_policy ON habit_logs
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_logs_delete_policy ON habit_logs;
CREATE POLICY habit_logs_delete_policy ON habit_logs
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_logs_service_policy ON habit_logs;
CREATE POLICY habit_logs_service_policy ON habit_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Habit Streaks Policies - Users can only see/modify their own streaks
DROP POLICY IF EXISTS habit_streaks_select_policy ON habit_streaks;
CREATE POLICY habit_streaks_select_policy ON habit_streaks
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_streaks_insert_policy ON habit_streaks;
CREATE POLICY habit_streaks_insert_policy ON habit_streaks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_streaks_update_policy ON habit_streaks;
CREATE POLICY habit_streaks_update_policy ON habit_streaks
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_streaks_delete_policy ON habit_streaks;
CREATE POLICY habit_streaks_delete_policy ON habit_streaks
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS habit_streaks_service_policy ON habit_streaks;
CREATE POLICY habit_streaks_service_policy ON habit_streaks
    FOR ALL USING (auth.role() = 'service_role');

-- Habit Templates Policies - Public read access (templates are shared)
DROP POLICY IF EXISTS habit_templates_select_policy ON habit_templates;
CREATE POLICY habit_templates_select_policy ON habit_templates
    FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS habit_templates_service_policy ON habit_templates;
CREATE POLICY habit_templates_service_policy ON habit_templates
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================

-- Update habits.updated_at trigger
CREATE OR REPLACE FUNCTION update_habits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_habits_updated_at ON habits;
CREATE TRIGGER trigger_habits_updated_at
    BEFORE UPDATE ON habits
    FOR EACH ROW
    EXECUTE FUNCTION update_habits_updated_at();

-- Update habit_streaks.updated_at trigger
CREATE OR REPLACE FUNCTION update_habit_streaks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_habit_streaks_updated_at ON habit_streaks;
CREATE TRIGGER trigger_habit_streaks_updated_at
    BEFORE UPDATE ON habit_streaks
    FOR EACH ROW
    EXECUTE FUNCTION update_habit_streaks_updated_at();

-- ============================================================================
-- STREAK UPDATE FUNCTION
-- ============================================================================
-- Updates habit_streaks when a habit_log is inserted or updated

CREATE OR REPLACE FUNCTION update_habit_streak()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_last_completed DATE;
    v_streak_start DATE;
    v_yesterday DATE;
    v_habit_frequency TEXT;
BEGIN
    -- Get habit frequency
    SELECT frequency INTO v_habit_frequency
    FROM habits
    WHERE id = NEW.habit_id;

    -- Only process for daily habits for now
    -- Weekly and specific_days habits need more complex logic
    IF v_habit_frequency != 'daily' THEN
        RETURN NEW;
    END IF;

    v_yesterday := NEW.log_date - INTERVAL '1 day';

    -- Get current streak info
    SELECT current_streak, longest_streak, last_completed_date, streak_start_date
    INTO v_current_streak, v_longest_streak, v_last_completed, v_streak_start
    FROM habit_streaks
    WHERE habit_id = NEW.habit_id;

    -- If no streak record exists, create one
    IF NOT FOUND THEN
        IF NEW.completed = TRUE THEN
            INSERT INTO habit_streaks (habit_id, user_id, current_streak, longest_streak, last_completed_date, streak_start_date)
            VALUES (NEW.habit_id, NEW.user_id, 1, 1, NEW.log_date, NEW.log_date);
        ELSE
            INSERT INTO habit_streaks (habit_id, user_id, current_streak, longest_streak, last_completed_date, streak_start_date)
            VALUES (NEW.habit_id, NEW.user_id, 0, 0, NULL, NULL);
        END IF;
        RETURN NEW;
    END IF;

    -- Handle completion
    IF NEW.completed = TRUE THEN
        -- Check if this continues the streak
        IF v_last_completed = v_yesterday OR v_last_completed = NEW.log_date THEN
            -- Continue or maintain streak
            IF v_last_completed != NEW.log_date THEN
                v_current_streak := v_current_streak + 1;
            END IF;
        ELSIF v_last_completed IS NULL OR NEW.log_date > v_last_completed + INTERVAL '1 day' THEN
            -- Start new streak
            v_current_streak := 1;
            v_streak_start := NEW.log_date;
        END IF;

        -- Update longest streak if needed
        IF v_current_streak > v_longest_streak THEN
            v_longest_streak := v_current_streak;
        END IF;

        -- Update the streak record
        UPDATE habit_streaks
        SET current_streak = v_current_streak,
            longest_streak = v_longest_streak,
            last_completed_date = NEW.log_date,
            streak_start_date = COALESCE(v_streak_start, streak_start_date, NEW.log_date),
            updated_at = NOW()
        WHERE habit_id = NEW.habit_id;

    ELSE
        -- Handle un-completion (if user marks as not completed)
        -- Check if this breaks the streak
        IF v_last_completed = NEW.log_date THEN
            -- User is un-completing today's habit
            -- Recalculate streak by checking yesterday
            IF EXISTS (
                SELECT 1 FROM habit_logs
                WHERE habit_id = NEW.habit_id
                AND log_date = v_yesterday
                AND completed = TRUE
            ) THEN
                -- Yesterday was completed, streak continues from before
                v_current_streak := v_current_streak - 1;
                IF v_current_streak < 0 THEN v_current_streak := 0; END IF;

                -- Find the new last completed date
                SELECT MAX(log_date) INTO v_last_completed
                FROM habit_logs
                WHERE habit_id = NEW.habit_id
                AND log_date < NEW.log_date
                AND completed = TRUE;
            ELSE
                -- Yesterday wasn't completed, reset streak
                v_current_streak := 0;
                v_last_completed := NULL;
                v_streak_start := NULL;
            END IF;

            UPDATE habit_streaks
            SET current_streak = v_current_streak,
                last_completed_date = v_last_completed,
                streak_start_date = v_streak_start,
                updated_at = NOW()
            WHERE habit_id = NEW.habit_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger to update streaks on habit_log changes
DROP TRIGGER IF EXISTS trigger_update_habit_streak ON habit_logs;
CREATE TRIGGER trigger_update_habit_streak
    AFTER INSERT OR UPDATE OF completed ON habit_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_habit_streak();

-- ============================================================================
-- HELPER FUNCTION: Initialize streak on habit creation
-- ============================================================================

CREATE OR REPLACE FUNCTION initialize_habit_streak()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO habit_streaks (habit_id, user_id, current_streak, longest_streak)
    VALUES (NEW.id, NEW.user_id, 0, 0)
    ON CONFLICT (habit_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_initialize_habit_streak ON habits;
CREATE TRIGGER trigger_initialize_habit_streak
    AFTER INSERT ON habits
    FOR EACH ROW
    EXECUTE FUNCTION initialize_habit_streak();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Today's Habits View - Shows user's habits with today's completion status
CREATE OR REPLACE VIEW today_habits_view AS
SELECT
    h.id AS habit_id,
    h.user_id,
    h.name,
    h.description,
    h.category,
    h.habit_type,
    h.frequency,
    h.target_days,
    h.target_count,
    h.unit,
    h.icon,
    h.color,
    h.reminder_time,
    h.reminder_enabled,
    h.is_suggested,
    hl.id AS log_id,
    COALESCE(hl.completed, FALSE) AS completed,
    hl.value,
    hl.notes,
    COALESCE(hl.skipped, FALSE) AS skipped,
    hl.skip_reason,
    hl.completed_at,
    hs.current_streak,
    hs.longest_streak,
    h.created_at AS habit_created_at
FROM habits h
LEFT JOIN habit_logs hl ON h.id = hl.habit_id AND hl.log_date = CURRENT_DATE
LEFT JOIN habit_streaks hs ON h.id = hs.habit_id
WHERE h.is_active = TRUE
ORDER BY h.created_at;

-- Weekly Habit Summary View - Aggregated completion rates for the past 7 days
CREATE OR REPLACE VIEW habit_weekly_summary_view AS
SELECT
    h.id AS habit_id,
    h.user_id,
    h.name,
    h.category,
    h.habit_type,
    h.icon,
    h.color,
    hs.current_streak,
    hs.longest_streak,
    COUNT(hl.id) FILTER (WHERE hl.log_date >= CURRENT_DATE - INTERVAL '6 days') AS days_tracked,
    COUNT(hl.id) FILTER (WHERE hl.completed = TRUE AND hl.log_date >= CURRENT_DATE - INTERVAL '6 days') AS days_completed,
    COUNT(hl.id) FILTER (WHERE hl.skipped = TRUE AND hl.log_date >= CURRENT_DATE - INTERVAL '6 days') AS days_skipped,
    ROUND(
        COALESCE(
            COUNT(hl.id) FILTER (WHERE hl.completed = TRUE AND hl.log_date >= CURRENT_DATE - INTERVAL '6 days')::NUMERIC /
            NULLIF(COUNT(hl.id) FILTER (WHERE hl.log_date >= CURRENT_DATE - INTERVAL '6 days'), 0) * 100,
            0
        ),
        1
    ) AS completion_rate,
    -- Daily completion array for sparkline charts (last 7 days)
    ARRAY_AGG(
        CASE WHEN hl.completed = TRUE THEN 1 WHEN hl.skipped = TRUE THEN -1 ELSE 0 END
        ORDER BY hl.log_date
    ) FILTER (WHERE hl.log_date >= CURRENT_DATE - INTERVAL '6 days') AS daily_status
FROM habits h
LEFT JOIN habit_logs hl ON h.id = hl.habit_id
LEFT JOIN habit_streaks hs ON h.id = hs.habit_id
WHERE h.is_active = TRUE
GROUP BY h.id, h.user_id, h.name, h.category, h.habit_type, h.icon, h.color,
         hs.current_streak, hs.longest_streak;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON habits TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON habit_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON habit_streaks TO authenticated;
GRANT SELECT ON habit_templates TO authenticated;
GRANT SELECT ON today_habits_view TO authenticated;
GRANT SELECT ON habit_weekly_summary_view TO authenticated;

GRANT EXECUTE ON FUNCTION update_habit_streak TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_habit_streak TO authenticated;
GRANT EXECUTE ON FUNCTION update_habits_updated_at TO authenticated;
GRANT EXECUTE ON FUNCTION update_habit_streaks_updated_at TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE habits IS 'Master table for user habit definitions with customizable tracking settings';
COMMENT ON TABLE habit_logs IS 'Daily completion logs for each habit with optional value and notes';
COMMENT ON TABLE habit_streaks IS 'Current and longest streak tracking for each habit';
COMMENT ON TABLE habit_templates IS 'Pre-defined habit templates for quick habit creation suggestions';

COMMENT ON COLUMN habits.habit_type IS 'positive = do something (e.g., walk), negative = avoid something (e.g., no junk food)';
COMMENT ON COLUMN habits.frequency IS 'daily = every day, weekly = X times per week, specific_days = only on certain days';
COMMENT ON COLUMN habits.target_days IS 'For specific_days frequency: array of day numbers (0=Sunday, 6=Saturday)';
COMMENT ON COLUMN habits.target_count IS 'Target value for quantitative habits (e.g., 10000 for steps goal)';
COMMENT ON COLUMN habits.is_suggested IS 'True if this habit was suggested by AI based on user goals';

COMMENT ON COLUMN habit_logs.value IS 'Numeric value for quantitative habits (e.g., actual step count)';
COMMENT ON COLUMN habit_logs.skipped IS 'True if user explicitly chose to skip this habit for the day';

COMMENT ON VIEW today_habits_view IS 'User habits with today completion status and current streak';
COMMENT ON VIEW habit_weekly_summary_view IS 'Weekly aggregated completion rates for each habit';

COMMENT ON FUNCTION update_habit_streak IS 'Automatically updates habit_streaks when habit_logs are created or modified';
COMMENT ON FUNCTION initialize_habit_streak IS 'Creates initial habit_streak record when a new habit is created';
