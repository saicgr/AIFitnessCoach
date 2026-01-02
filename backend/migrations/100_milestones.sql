-- Migration 100: Progress Milestones and ROI Communication
-- Tracks user milestones, achievements, and ROI metrics for demonstrating fitness progress value

-- ============================================
-- Milestone Definitions Table
-- ============================================
-- Defines all possible milestones users can achieve
CREATE TABLE IF NOT EXISTS milestone_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- 'workouts', 'streak', 'strength', 'volume', 'time', 'weight', 'prs'
    threshold INTEGER NOT NULL, -- e.g., 10 for "10 workouts"
    icon VARCHAR(50), -- emoji icon for the milestone
    badge_color VARCHAR(20) DEFAULT 'cyan', -- badge background color
    tier VARCHAR(20) DEFAULT 'bronze', -- 'bronze', 'silver', 'gold', 'platinum', 'diamond'
    points INTEGER DEFAULT 10, -- points awarded for this milestone
    share_message TEXT, -- template for sharing (e.g., "I just completed my {threshold}th workout!")
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for category queries
CREATE INDEX IF NOT EXISTS idx_milestone_definitions_category ON milestone_definitions(category);
CREATE INDEX IF NOT EXISTS idx_milestone_definitions_active ON milestone_definitions(is_active);

-- ============================================
-- User Milestones Table
-- ============================================
-- Tracks which milestones each user has achieved
CREATE TABLE IF NOT EXISTS user_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    milestone_id UUID NOT NULL REFERENCES milestone_definitions(id) ON DELETE CASCADE,
    achieved_at TIMESTAMPTZ DEFAULT NOW(),
    trigger_value FLOAT, -- the actual value that triggered the milestone (e.g., 100 workouts)
    trigger_context JSONB, -- additional context (e.g., workout_id, exercise_name)
    is_notified BOOLEAN DEFAULT false, -- whether the user has been notified
    is_celebrated BOOLEAN DEFAULT false, -- whether celebration dialog was shown
    shared_at TIMESTAMPTZ, -- when user shared (if ever)
    share_platform VARCHAR(50), -- 'twitter', 'instagram', 'facebook', etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, milestone_id)
);

-- Create indexes for user milestone queries
CREATE INDEX IF NOT EXISTS idx_user_milestones_user_id ON user_milestones(user_id);
CREATE INDEX IF NOT EXISTS idx_user_milestones_achieved_at ON user_milestones(achieved_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_milestones_not_notified ON user_milestones(user_id, is_notified) WHERE is_notified = false;
CREATE INDEX IF NOT EXISTS idx_user_milestones_not_celebrated ON user_milestones(user_id, is_celebrated) WHERE is_celebrated = false;

-- ============================================
-- ROI Metrics Cache Table
-- ============================================
-- Caches calculated ROI metrics for faster retrieval
-- Updated after each workout completion
CREATE TABLE IF NOT EXISTS user_roi_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    -- Workout metrics
    total_workouts_completed INTEGER DEFAULT 0,
    total_exercises_completed INTEGER DEFAULT 0,
    total_sets_completed INTEGER DEFAULT 0,
    total_reps_completed INTEGER DEFAULT 0,
    -- Time metrics
    total_workout_time_seconds INTEGER DEFAULT 0,
    total_active_time_seconds INTEGER DEFAULT 0,
    average_workout_duration_seconds INTEGER DEFAULT 0,
    -- Volume metrics
    total_weight_lifted_lbs FLOAT DEFAULT 0,
    total_weight_lifted_kg FLOAT DEFAULT 0,
    -- Calorie metrics (estimated)
    estimated_calories_burned INTEGER DEFAULT 0,
    -- Progress metrics
    strength_increase_percentage FLOAT DEFAULT 0, -- compared to first month
    prs_achieved_count INTEGER DEFAULT 0,
    current_streak_days INTEGER DEFAULT 0,
    longest_streak_days INTEGER DEFAULT 0,
    -- First workout date for calculating journey duration
    first_workout_date TIMESTAMPTZ,
    last_workout_date TIMESTAMPTZ,
    journey_days INTEGER DEFAULT 0,
    -- Workout frequency
    workouts_this_week INTEGER DEFAULT 0,
    workouts_this_month INTEGER DEFAULT 0,
    average_workouts_per_week FLOAT DEFAULT 0,
    -- Timestamps
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for ROI metrics queries
CREATE INDEX IF NOT EXISTS idx_user_roi_metrics_user_id ON user_roi_metrics(user_id);

-- ============================================
-- Seed Milestone Definitions
-- ============================================

-- Workouts Category
INSERT INTO milestone_definitions (name, description, category, threshold, icon, tier, points, badge_color, share_message, sort_order) VALUES
-- First Steps
('First Workout', 'Completed your first workout! The journey begins.', 'workouts', 1, 'trophy', 'bronze', 10, 'cyan', 'I just completed my first workout with FitWiz!', 1),
('Getting Started', 'Completed 5 workouts. Building momentum!', 'workouts', 5, 'fire', 'bronze', 25, 'orange', 'I''ve completed 5 workouts and building great habits!', 2),
('Building Habits', 'Completed 10 workouts. Consistency is key!', 'workouts', 10, 'muscle', 'bronze', 50, 'purple', 'Just hit 10 workouts! Habits are forming.', 3),
('Dedicated', 'Completed 25 workouts. True dedication!', 'workouts', 25, 'star', 'silver', 100, 'yellow', '25 workouts complete! Dedicated to the grind.', 4),
('Committed', 'Completed 50 workouts. Half a century!', 'workouts', 50, 'flame', 'silver', 200, 'coral', '50 workouts in the books! Commitment pays off.', 5),
('Centurion', 'Completed 100 workouts. Welcome to the century club!', 'workouts', 100, 'trophy', 'gold', 500, 'gold', 'CENTURION! 100 workouts completed!', 6),
('Legend', 'Completed 250 workouts. Legendary status achieved!', 'workouts', 250, 'crown', 'platinum', 1000, 'purple', '250 workouts! Legendary fitness journey!', 7),
('Titan', 'Completed 500 workouts. You are unstoppable!', 'workouts', 500, 'diamond', 'diamond', 2500, 'cyan', '500 WORKOUTS! I am a TITAN!', 8),

-- Streak Category
('Week Warrior', 'Achieved a 7-day workout streak!', 'streak', 7, 'calendar', 'bronze', 75, 'green', '7 days straight! Week Warrior status!', 10),
('Two Week Terror', 'Achieved a 14-day workout streak!', 'streak', 14, 'fire', 'silver', 150, 'orange', '14-day streak! Unstoppable!', 11),
('Month Master', 'Achieved a 30-day workout streak!', 'streak', 30, 'crown', 'gold', 300, 'gold', '30 DAYS IN A ROW! Month Master!', 12),
('Quarter Champion', 'Achieved a 90-day workout streak!', 'streak', 90, 'trophy', 'platinum', 750, 'purple', '90-day streak! Quarter Champion!', 13),
('Year King', 'Achieved a 365-day workout streak!', 'streak', 365, 'diamond', 'diamond', 5000, 'cyan', '365 DAYS! YEAR KING!', 14),

-- Strength Category (PRs)
('First PR', 'Set your first personal record!', 'strength', 1, 'medal', 'bronze', 25, 'gold', 'Just set my first personal record!', 20),
('PR Hunter', 'Achieved 10 personal records!', 'strength', 10, 'target', 'silver', 100, 'coral', '10 PRs smashed! PR Hunter mode!', 21),
('PR Master', 'Achieved 25 personal records!', 'strength', 25, 'star', 'gold', 250, 'purple', '25 personal records! Master of gains!', 22),
('PR Legend', 'Achieved 50 personal records!', 'strength', 50, 'crown', 'platinum', 500, 'cyan', '50 PRs! LEGEND status!', 23),
('PR God', 'Achieved 100 personal records!', 'strength', 100, 'diamond', 'diamond', 1000, 'gold', '100 PERSONAL RECORDS! PR GOD!', 24),

-- Time Category
('Hour Hero', 'Worked out for 10+ hours total!', 'time', 10, 'clock', 'bronze', 50, 'cyan', '10 hours invested in my fitness!', 30),
('Time Champion', 'Worked out for 50+ hours total!', 'time', 50, 'hourglass', 'silver', 200, 'purple', '50 hours of training! Time Champion!', 31),
('Century Hours', 'Worked out for 100+ hours total!', 'time', 100, 'trophy', 'gold', 500, 'gold', '100 HOURS of sweat and dedication!', 32),
('Time Legend', 'Worked out for 250+ hours total!', 'time', 250, 'crown', 'platinum', 1000, 'coral', '250 hours! True Time Legend!', 33),
('Time Titan', 'Worked out for 500+ hours total!', 'time', 500, 'diamond', 'diamond', 2500, 'cyan', '500 HOURS! TIME TITAN!', 34),

-- Volume Category (Weight Lifted)
('First Ton', 'Lifted 2,000+ lbs total!', 'volume', 2000, 'dumbbell', 'bronze', 50, 'purple', 'Just lifted my first ton!', 40),
('Heavy Lifter', 'Lifted 10,000+ lbs total!', 'volume', 10000, 'muscle', 'silver', 150, 'orange', '10,000 lbs lifted! Heavy Lifter!', 41),
('50K Club', 'Lifted 50,000+ lbs total!', 'volume', 50000, 'star', 'gold', 300, 'gold', 'Welcome to the 50K Club!', 42),
('100K Crusher', 'Lifted 100,000+ lbs total!', 'volume', 100000, 'trophy', 'platinum', 750, 'coral', '100,000 lbs CRUSHED!', 43),
('Million Pound Club', 'Lifted 1,000,000+ lbs total!', 'volume', 1000000, 'diamond', 'diamond', 5000, 'cyan', 'MILLION POUND CLUB! LEGENDARY!', 44),

-- Weight Loss/Gain Progress (optional - only if user is tracking weight)
('First 5', 'Lost or gained your first 5 lbs toward goal!', 'weight', 5, 'scale', 'bronze', 100, 'green', '5 lbs closer to my goal!', 50),
('10 Down', 'Lost or gained 10 lbs toward goal!', 'weight', 10, 'flame', 'silver', 250, 'cyan', '10 lbs of progress!', 51),
('20 Transformation', 'Lost or gained 20 lbs toward goal!', 'weight', 20, 'trophy', 'gold', 500, 'gold', '20 lbs transformation complete!', 52),
('30 Milestone', 'Lost or gained 30 lbs toward goal!', 'weight', 30, 'crown', 'platinum', 1000, 'purple', '30 lbs! Incredible transformation!', 53)
ON CONFLICT DO NOTHING;

-- ============================================
-- Row Level Security (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE milestone_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roi_metrics ENABLE ROW LEVEL SECURITY;

-- Milestone definitions are readable by all authenticated users
DROP POLICY IF EXISTS "Anyone can read milestone definitions" ON milestone_definitions;
CREATE POLICY "Anyone can read milestone definitions" ON milestone_definitions
    FOR SELECT USING (true);

-- Users can only see their own milestones
DROP POLICY IF EXISTS "Users can view own milestones" ON user_milestones;
CREATE POLICY "Users can view own milestones" ON user_milestones
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own milestones" ON user_milestones;
CREATE POLICY "Users can insert own milestones" ON user_milestones
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own milestones" ON user_milestones;
CREATE POLICY "Users can update own milestones" ON user_milestones
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can only see their own ROI metrics
DROP POLICY IF EXISTS "Users can view own ROI metrics" ON user_roi_metrics;
CREATE POLICY "Users can view own ROI metrics" ON user_roi_metrics
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own ROI metrics" ON user_roi_metrics;
CREATE POLICY "Users can manage own ROI metrics" ON user_roi_metrics
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- Helper Functions
-- ============================================

-- Function to calculate and update ROI metrics for a user
CREATE OR REPLACE FUNCTION calculate_user_roi_metrics(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_first_workout TIMESTAMPTZ;
    v_last_workout TIMESTAMPTZ;
    v_total_workouts INTEGER;
    v_total_time INTEGER;
    v_total_weight FLOAT;
    v_total_prs INTEGER;
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_week_workouts INTEGER;
    v_month_workouts INTEGER;
BEGIN
    -- Get workout stats
    SELECT
        MIN(created_at),
        MAX(created_at),
        COUNT(*),
        COALESCE(SUM(duration_seconds), 0)
    INTO v_first_workout, v_last_workout, v_total_workouts, v_total_time
    FROM workout_logs
    WHERE user_id = p_user_id
    AND status = 'completed';

    -- Get total weight lifted (from exercise_logs)
    SELECT COALESCE(SUM(
        CASE
            WHEN weight_unit = 'kg' THEN weight_used * 2.20462 * reps_completed * sets_completed
            ELSE weight_used * reps_completed * sets_completed
        END
    ), 0)
    INTO v_total_weight
    FROM exercise_logs el
    JOIN workout_logs wl ON el.workout_log_id = wl.id
    WHERE wl.user_id = p_user_id
    AND wl.status = 'completed';

    -- Get PR count
    SELECT COUNT(*) INTO v_total_prs
    FROM personal_records
    WHERE user_id = p_user_id;

    -- Get streak info from user_streaks table
    SELECT COALESCE(current_streak, 0), COALESCE(longest_streak, 0)
    INTO v_current_streak, v_longest_streak
    FROM user_streaks
    WHERE user_id = p_user_id AND streak_type = 'workout';

    -- Get this week's workouts
    SELECT COUNT(*) INTO v_week_workouts
    FROM workout_logs
    WHERE user_id = p_user_id
    AND status = 'completed'
    AND created_at >= date_trunc('week', NOW());

    -- Get this month's workouts
    SELECT COUNT(*) INTO v_month_workouts
    FROM workout_logs
    WHERE user_id = p_user_id
    AND status = 'completed'
    AND created_at >= date_trunc('month', NOW());

    -- Upsert ROI metrics
    INSERT INTO user_roi_metrics (
        user_id,
        total_workouts_completed,
        total_workout_time_seconds,
        total_weight_lifted_lbs,
        total_weight_lifted_kg,
        estimated_calories_burned,
        prs_achieved_count,
        current_streak_days,
        longest_streak_days,
        first_workout_date,
        last_workout_date,
        journey_days,
        workouts_this_week,
        workouts_this_month,
        average_workouts_per_week,
        last_calculated_at
    ) VALUES (
        p_user_id,
        v_total_workouts,
        v_total_time,
        v_total_weight,
        v_total_weight / 2.20462,
        (v_total_time / 60) * 7, -- ~7 calories per minute estimate
        v_total_prs,
        v_current_streak,
        v_longest_streak,
        v_first_workout,
        v_last_workout,
        EXTRACT(DAY FROM (NOW() - v_first_workout))::INTEGER,
        v_week_workouts,
        v_month_workouts,
        CASE
            WHEN v_first_workout IS NOT NULL
            THEN v_total_workouts::FLOAT / GREATEST(1, EXTRACT(WEEK FROM (NOW() - v_first_workout)))
            ELSE 0
        END,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_workouts_completed = EXCLUDED.total_workouts_completed,
        total_workout_time_seconds = EXCLUDED.total_workout_time_seconds,
        total_weight_lifted_lbs = EXCLUDED.total_weight_lifted_lbs,
        total_weight_lifted_kg = EXCLUDED.total_weight_lifted_kg,
        estimated_calories_burned = EXCLUDED.estimated_calories_burned,
        prs_achieved_count = EXCLUDED.prs_achieved_count,
        current_streak_days = EXCLUDED.current_streak_days,
        longest_streak_days = EXCLUDED.longest_streak_days,
        first_workout_date = EXCLUDED.first_workout_date,
        last_workout_date = EXCLUDED.last_workout_date,
        journey_days = EXCLUDED.journey_days,
        workouts_this_week = EXCLUDED.workouts_this_week,
        workouts_this_month = EXCLUDED.workouts_this_month,
        average_workouts_per_week = EXCLUDED.average_workouts_per_week,
        last_calculated_at = NOW(),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to check and award milestones after workout completion
CREATE OR REPLACE FUNCTION check_and_award_milestones(p_user_id UUID)
RETURNS TABLE (
    milestone_id UUID,
    milestone_name VARCHAR(100),
    milestone_icon VARCHAR(50),
    milestone_tier VARCHAR(20),
    points INTEGER
) AS $$
DECLARE
    v_roi user_roi_metrics%ROWTYPE;
    v_milestone milestone_definitions%ROWTYPE;
BEGIN
    -- First, calculate/update ROI metrics
    PERFORM calculate_user_roi_metrics(p_user_id);

    -- Get the updated metrics
    SELECT * INTO v_roi FROM user_roi_metrics WHERE user_id = p_user_id;

    IF v_roi IS NULL THEN
        RETURN;
    END IF;

    -- Check each category and award milestones
    FOR v_milestone IN
        SELECT * FROM milestone_definitions
        WHERE is_active = true
        ORDER BY category, threshold
    LOOP
        -- Skip if already achieved
        CONTINUE WHEN EXISTS (
            SELECT 1 FROM user_milestones
            WHERE user_id = p_user_id AND milestone_id = v_milestone.id
        );

        -- Check if milestone is achieved based on category
        IF (v_milestone.category = 'workouts' AND v_roi.total_workouts_completed >= v_milestone.threshold) OR
           (v_milestone.category = 'streak' AND v_roi.longest_streak_days >= v_milestone.threshold) OR
           (v_milestone.category = 'strength' AND v_roi.prs_achieved_count >= v_milestone.threshold) OR
           (v_milestone.category = 'time' AND (v_roi.total_workout_time_seconds / 3600) >= v_milestone.threshold) OR
           (v_milestone.category = 'volume' AND v_roi.total_weight_lifted_lbs >= v_milestone.threshold)
        THEN
            -- Award the milestone
            INSERT INTO user_milestones (user_id, milestone_id, trigger_value)
            VALUES (p_user_id, v_milestone.id,
                CASE v_milestone.category
                    WHEN 'workouts' THEN v_roi.total_workouts_completed
                    WHEN 'streak' THEN v_roi.longest_streak_days
                    WHEN 'strength' THEN v_roi.prs_achieved_count
                    WHEN 'time' THEN v_roi.total_workout_time_seconds / 3600
                    WHEN 'volume' THEN v_roi.total_weight_lifted_lbs
                    ELSE 0
                END
            );

            -- Return the newly awarded milestone
            milestone_id := v_milestone.id;
            milestone_name := v_milestone.name;
            milestone_icon := v_milestone.icon;
            milestone_tier := v_milestone.tier;
            points := v_milestone.points;
            RETURN NEXT;
        END IF;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Views for easier querying
-- ============================================

-- View for milestone progress (shows achieved and upcoming)
CREATE OR REPLACE VIEW user_milestone_progress AS
SELECT
    md.id,
    md.name,
    md.description,
    md.category,
    md.threshold,
    md.icon,
    md.badge_color,
    md.tier,
    md.points,
    md.share_message,
    um.user_id,
    um.achieved_at,
    um.trigger_value,
    um.is_celebrated,
    um.shared_at,
    CASE WHEN um.id IS NOT NULL THEN true ELSE false END as is_achieved,
    md.sort_order
FROM milestone_definitions md
LEFT JOIN user_milestones um ON md.id = um.milestone_id
WHERE md.is_active = true
ORDER BY md.category, md.sort_order, md.threshold;

-- ============================================
-- Trigger to auto-check milestones on workout completion
-- ============================================

-- Note: This trigger should be added to the workout_logs table
-- It will automatically check and award milestones when a workout is completed
CREATE OR REPLACE FUNCTION trigger_check_milestones_on_workout()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        PERFORM check_and_award_milestones(NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger (only if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'trg_check_milestones_on_workout'
    ) THEN
        CREATE TRIGGER trg_check_milestones_on_workout
        AFTER INSERT OR UPDATE ON workout_logs
        FOR EACH ROW
        EXECUTE FUNCTION trigger_check_milestones_on_workout();
    END IF;
END;
$$;

-- ============================================
-- Grants for service role
-- ============================================
GRANT ALL ON milestone_definitions TO service_role;
GRANT ALL ON user_milestones TO service_role;
GRANT ALL ON user_roi_metrics TO service_role;
GRANT EXECUTE ON FUNCTION calculate_user_roi_metrics(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION check_and_award_milestones(UUID) TO service_role;
