-- Migration: NEAT (Non-Exercise Activity Thermogenesis) Improvement System
-- Created: 2025-12-30
-- Purpose: Track daily activity, step goals, hourly movement, and gamification for NEAT improvement

-- ============================================
-- neat_goals - User step goals with progressive targeting
-- ============================================
CREATE TABLE IF NOT EXISTS neat_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_step_goal INTEGER NOT NULL DEFAULT 5000,
    baseline_steps INTEGER,  -- User's average steps when they started
    goal_increment INTEGER NOT NULL DEFAULT 500,  -- How much to increase weekly
    goal_type TEXT NOT NULL DEFAULT 'steps' CHECK (goal_type IN ('steps', 'active_hours', 'neat_score')),
    min_goal INTEGER DEFAULT 3000,  -- Minimum goal floor
    max_goal INTEGER DEFAULT 15000,  -- Maximum goal ceiling
    last_goal_update DATE,  -- When goal was last auto-adjusted
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, goal_type)
);

COMMENT ON TABLE neat_goals IS 'Stores user NEAT goals with progressive targeting system';
COMMENT ON COLUMN neat_goals.baseline_steps IS 'User average steps when they started - used for progress calculation';
COMMENT ON COLUMN neat_goals.goal_increment IS 'Amount to increase goal by weekly when consistently meeting targets';
COMMENT ON COLUMN neat_goals.last_goal_update IS 'Tracks when goal was last auto-adjusted to prevent over-adjustment';

-- Indexes for neat_goals
CREATE INDEX IF NOT EXISTS idx_neat_goals_user_id ON neat_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_neat_goals_goal_type ON neat_goals(goal_type);

-- ============================================
-- neat_hourly_activity - Tracks steps per hour for sedentary detection
-- ============================================
CREATE TABLE IF NOT EXISTS neat_hourly_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    hour INTEGER NOT NULL CHECK (hour >= 0 AND hour <= 23),
    steps INTEGER NOT NULL DEFAULT 0,
    is_sedentary BOOLEAN GENERATED ALWAYS AS (steps < 250) STORED,
    reminder_sent BOOLEAN DEFAULT FALSE,
    source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('health_connect', 'apple_health', 'fitbit', 'garmin', 'manual')),
    calories_burned INTEGER,  -- Estimated calories for this hour
    distance_meters INTEGER,  -- Distance covered this hour
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, activity_date, hour)
);

COMMENT ON TABLE neat_hourly_activity IS 'Tracks hourly step data for sedentary detection and movement reminders';
COMMENT ON COLUMN neat_hourly_activity.is_sedentary IS 'Auto-calculated: true if fewer than 250 steps in the hour';
COMMENT ON COLUMN neat_hourly_activity.reminder_sent IS 'Whether a movement reminder was sent for this sedentary hour';

-- Indexes for neat_hourly_activity
CREATE INDEX IF NOT EXISTS idx_neat_hourly_activity_user_id ON neat_hourly_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_neat_hourly_activity_date ON neat_hourly_activity(activity_date);
CREATE INDEX IF NOT EXISTS idx_neat_hourly_activity_user_date ON neat_hourly_activity(user_id, activity_date);
CREATE INDEX IF NOT EXISTS idx_neat_hourly_activity_sedentary ON neat_hourly_activity(user_id, activity_date, is_sedentary);

-- ============================================
-- neat_daily_scores - Daily NEAT score calculation
-- ============================================
CREATE TABLE IF NOT EXISTS neat_daily_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    score_date DATE NOT NULL,
    neat_score INTEGER NOT NULL DEFAULT 0 CHECK (neat_score >= 0 AND neat_score <= 100),
    total_steps INTEGER NOT NULL DEFAULT 0,
    active_hours INTEGER NOT NULL DEFAULT 0,  -- Hours with 250+ steps
    sedentary_hours INTEGER NOT NULL DEFAULT 0,  -- Hours with < 250 steps
    step_goal_achieved BOOLEAN NOT NULL DEFAULT FALSE,
    goal_at_time INTEGER NOT NULL,  -- What the step goal was that day
    active_hours_goal INTEGER DEFAULT 10,  -- Target active hours
    -- Additional metrics
    total_distance_meters INTEGER,
    total_calories_burned INTEGER,
    longest_active_streak INTEGER,  -- Longest consecutive active hours
    longest_sedentary_streak INTEGER,  -- Longest consecutive sedentary hours (alert trigger)
    peak_hour INTEGER,  -- Hour with most steps
    peak_hour_steps INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, score_date)
);

COMMENT ON TABLE neat_daily_scores IS 'Daily aggregated NEAT metrics and score calculation';
COMMENT ON COLUMN neat_daily_scores.neat_score IS 'Calculated 0-100 score based on steps, active hours, and consistency';
COMMENT ON COLUMN neat_daily_scores.goal_at_time IS 'Preserves the goal that was active on that day for accurate historical tracking';

-- Indexes for neat_daily_scores
CREATE INDEX IF NOT EXISTS idx_neat_daily_scores_user_id ON neat_daily_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_neat_daily_scores_date ON neat_daily_scores(score_date);
CREATE INDEX IF NOT EXISTS idx_neat_daily_scores_user_date ON neat_daily_scores(user_id, score_date DESC);
CREATE INDEX IF NOT EXISTS idx_neat_daily_scores_achieved ON neat_daily_scores(user_id, step_goal_achieved);

-- ============================================
-- neat_streaks - Track consecutive days meeting NEAT goals
-- ============================================
CREATE TABLE IF NOT EXISTS neat_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    streak_type TEXT NOT NULL CHECK (streak_type IN ('steps', 'active_hours', 'neat_score', 'combined')),
    current_streak INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_achievement_date DATE,
    streak_start_date DATE,
    -- Streak milestones tracking
    reached_7_days BOOLEAN DEFAULT FALSE,
    reached_14_days BOOLEAN DEFAULT FALSE,
    reached_30_days BOOLEAN DEFAULT FALSE,
    reached_60_days BOOLEAN DEFAULT FALSE,
    reached_100_days BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, streak_type)
);

COMMENT ON TABLE neat_streaks IS 'Tracks consecutive days of meeting various NEAT goals';
COMMENT ON COLUMN neat_streaks.streak_type IS 'Type: steps (met step goal), active_hours (10+ active hours), neat_score (80+ score), combined (all three)';

-- Indexes for neat_streaks
CREATE INDEX IF NOT EXISTS idx_neat_streaks_user_id ON neat_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_neat_streaks_type ON neat_streaks(streak_type);
CREATE INDEX IF NOT EXISTS idx_neat_streaks_current ON neat_streaks(current_streak DESC);

-- ============================================
-- neat_achievements - Gamification badge definitions
-- ============================================
CREATE TABLE IF NOT EXISTS neat_achievements (
    id SERIAL PRIMARY KEY,
    achievement_key TEXT UNIQUE NOT NULL,  -- Unique identifier for code reference
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,  -- Emoji or icon identifier
    requirement_type TEXT NOT NULL CHECK (requirement_type IN (
        'single_day_steps', 'streak_steps', 'streak_active_hours', 'streak_neat_score',
        'total_steps', 'total_active_hours', 'single_day_active_hours',
        'improvement_percentage', 'consistency', 'early_bird', 'night_owl'
    )),
    requirement_value INTEGER NOT NULL,
    tier TEXT NOT NULL DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond')),
    points INTEGER NOT NULL DEFAULT 10,
    is_repeatable BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE neat_achievements IS 'Master list of all NEAT-related achievement definitions';
COMMENT ON COLUMN neat_achievements.achievement_key IS 'Unique key for programmatic reference';
COMMENT ON COLUMN neat_achievements.requirement_type IS 'Type of requirement to unlock this achievement';
COMMENT ON COLUMN neat_achievements.is_repeatable IS 'Whether achievement can be earned multiple times';

-- ============================================
-- user_neat_achievements - Junction table for earned achievements
-- ============================================
CREATE TABLE IF NOT EXISTS user_neat_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES neat_achievements(id) ON DELETE CASCADE,
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    trigger_value INTEGER,  -- The value that triggered the achievement
    trigger_date DATE,  -- The date associated with achieving
    times_earned INTEGER DEFAULT 1,  -- For repeatable achievements
    is_notified BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, achievement_id, trigger_date)  -- Allow same achievement on different dates for repeatable
);

COMMENT ON TABLE user_neat_achievements IS 'Tracks which NEAT achievements each user has earned';

-- Indexes for user_neat_achievements
CREATE INDEX IF NOT EXISTS idx_user_neat_achievements_user_id ON user_neat_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_neat_achievements_achievement ON user_neat_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_neat_achievements_achieved_at ON user_neat_achievements(achieved_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_neat_achievements_notified ON user_neat_achievements(is_notified) WHERE NOT is_notified;

-- ============================================
-- neat_reminder_preferences - User preferences for movement reminders
-- ============================================
CREATE TABLE IF NOT EXISTS neat_reminder_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    reminder_interval_minutes INTEGER NOT NULL DEFAULT 60 CHECK (reminder_interval_minutes >= 15 AND reminder_interval_minutes <= 180),
    steps_threshold INTEGER NOT NULL DEFAULT 250 CHECK (steps_threshold >= 50 AND steps_threshold <= 500),
    quiet_hours_start TIME NOT NULL DEFAULT '22:00',
    quiet_hours_end TIME NOT NULL DEFAULT '07:00',
    work_hours_only BOOLEAN NOT NULL DEFAULT FALSE,
    work_hours_start TIME DEFAULT '09:00',
    work_hours_end TIME DEFAULT '17:00',
    -- Additional preferences
    weekend_reminders BOOLEAN DEFAULT TRUE,
    reminder_sound TEXT DEFAULT 'default',
    vibration_enabled BOOLEAN DEFAULT TRUE,
    smart_reminders BOOLEAN DEFAULT TRUE,  -- AI-powered reminder timing
    max_reminders_per_day INTEGER DEFAULT 8,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE neat_reminder_preferences IS 'User preferences for sedentary movement reminders';
COMMENT ON COLUMN neat_reminder_preferences.smart_reminders IS 'When enabled, AI optimizes reminder timing based on user patterns';

-- Index for neat_reminder_preferences
CREATE INDEX IF NOT EXISTS idx_neat_reminder_preferences_user_id ON neat_reminder_preferences(user_id);

-- ============================================
-- neat_weekly_summaries - Weekly aggregation for trends
-- ============================================
CREATE TABLE IF NOT EXISTS neat_weekly_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,  -- Monday of the week
    week_number INTEGER NOT NULL,
    year INTEGER NOT NULL,
    avg_daily_steps INTEGER NOT NULL DEFAULT 0,
    avg_neat_score INTEGER NOT NULL DEFAULT 0,
    avg_active_hours NUMERIC(4,2) NOT NULL DEFAULT 0,
    total_steps INTEGER NOT NULL DEFAULT 0,
    days_goal_achieved INTEGER NOT NULL DEFAULT 0,
    step_goal_at_time INTEGER NOT NULL,  -- Goal during this week
    improvement_from_baseline NUMERIC(5,2),  -- Percentage improvement from baseline
    improvement_from_last_week NUMERIC(5,2),  -- Week over week change
    best_day_steps INTEGER,
    best_day_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, week_start)
);

COMMENT ON TABLE neat_weekly_summaries IS 'Weekly aggregated NEAT data for trend analysis and goal adjustment';

-- Indexes for neat_weekly_summaries
CREATE INDEX IF NOT EXISTS idx_neat_weekly_summaries_user_id ON neat_weekly_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_neat_weekly_summaries_week ON neat_weekly_summaries(user_id, week_start DESC);

-- ============================================
-- Enable Row Level Security on all tables
-- ============================================
ALTER TABLE neat_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE neat_hourly_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE neat_daily_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE neat_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE neat_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_neat_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE neat_reminder_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE neat_weekly_summaries ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS Policies for neat_goals
-- ============================================
DROP POLICY IF EXISTS neat_goals_select_policy ON neat_goals;
CREATE POLICY neat_goals_select_policy ON neat_goals
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_goals_insert_policy ON neat_goals;
CREATE POLICY neat_goals_insert_policy ON neat_goals
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_goals_update_policy ON neat_goals;
CREATE POLICY neat_goals_update_policy ON neat_goals
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_goals_delete_policy ON neat_goals;
CREATE POLICY neat_goals_delete_policy ON neat_goals
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_goals_service_policy ON neat_goals;
CREATE POLICY neat_goals_service_policy ON neat_goals
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS Policies for neat_hourly_activity
-- ============================================
DROP POLICY IF EXISTS neat_hourly_activity_select_policy ON neat_hourly_activity;
CREATE POLICY neat_hourly_activity_select_policy ON neat_hourly_activity
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_hourly_activity_insert_policy ON neat_hourly_activity;
CREATE POLICY neat_hourly_activity_insert_policy ON neat_hourly_activity
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_hourly_activity_update_policy ON neat_hourly_activity;
CREATE POLICY neat_hourly_activity_update_policy ON neat_hourly_activity
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_hourly_activity_delete_policy ON neat_hourly_activity;
CREATE POLICY neat_hourly_activity_delete_policy ON neat_hourly_activity
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_hourly_activity_service_policy ON neat_hourly_activity;
CREATE POLICY neat_hourly_activity_service_policy ON neat_hourly_activity
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS Policies for neat_daily_scores
-- ============================================
DROP POLICY IF EXISTS neat_daily_scores_select_policy ON neat_daily_scores;
CREATE POLICY neat_daily_scores_select_policy ON neat_daily_scores
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_daily_scores_insert_policy ON neat_daily_scores;
CREATE POLICY neat_daily_scores_insert_policy ON neat_daily_scores
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_daily_scores_update_policy ON neat_daily_scores;
CREATE POLICY neat_daily_scores_update_policy ON neat_daily_scores
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_daily_scores_delete_policy ON neat_daily_scores;
CREATE POLICY neat_daily_scores_delete_policy ON neat_daily_scores
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_daily_scores_service_policy ON neat_daily_scores;
CREATE POLICY neat_daily_scores_service_policy ON neat_daily_scores
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS Policies for neat_streaks
-- ============================================
DROP POLICY IF EXISTS neat_streaks_select_policy ON neat_streaks;
CREATE POLICY neat_streaks_select_policy ON neat_streaks
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_streaks_insert_policy ON neat_streaks;
CREATE POLICY neat_streaks_insert_policy ON neat_streaks
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_streaks_update_policy ON neat_streaks;
CREATE POLICY neat_streaks_update_policy ON neat_streaks
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_streaks_delete_policy ON neat_streaks;
CREATE POLICY neat_streaks_delete_policy ON neat_streaks
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_streaks_service_policy ON neat_streaks;
CREATE POLICY neat_streaks_service_policy ON neat_streaks
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS Policies for neat_achievements (read-only for all)
-- ============================================
DROP POLICY IF EXISTS neat_achievements_select_policy ON neat_achievements;
CREATE POLICY neat_achievements_select_policy ON neat_achievements
    FOR SELECT USING (true);

DROP POLICY IF EXISTS neat_achievements_service_policy ON neat_achievements;
CREATE POLICY neat_achievements_service_policy ON neat_achievements
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS Policies for user_neat_achievements
-- ============================================
DROP POLICY IF EXISTS user_neat_achievements_select_policy ON user_neat_achievements;
CREATE POLICY user_neat_achievements_select_policy ON user_neat_achievements
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS user_neat_achievements_insert_policy ON user_neat_achievements;
CREATE POLICY user_neat_achievements_insert_policy ON user_neat_achievements
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS user_neat_achievements_update_policy ON user_neat_achievements;
CREATE POLICY user_neat_achievements_update_policy ON user_neat_achievements
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS user_neat_achievements_delete_policy ON user_neat_achievements;
CREATE POLICY user_neat_achievements_delete_policy ON user_neat_achievements
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS user_neat_achievements_service_policy ON user_neat_achievements;
CREATE POLICY user_neat_achievements_service_policy ON user_neat_achievements
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS Policies for neat_reminder_preferences
-- ============================================
DROP POLICY IF EXISTS neat_reminder_preferences_select_policy ON neat_reminder_preferences;
CREATE POLICY neat_reminder_preferences_select_policy ON neat_reminder_preferences
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_reminder_preferences_insert_policy ON neat_reminder_preferences;
CREATE POLICY neat_reminder_preferences_insert_policy ON neat_reminder_preferences
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_reminder_preferences_update_policy ON neat_reminder_preferences;
CREATE POLICY neat_reminder_preferences_update_policy ON neat_reminder_preferences
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_reminder_preferences_delete_policy ON neat_reminder_preferences;
CREATE POLICY neat_reminder_preferences_delete_policy ON neat_reminder_preferences
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_reminder_preferences_service_policy ON neat_reminder_preferences;
CREATE POLICY neat_reminder_preferences_service_policy ON neat_reminder_preferences
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- RLS Policies for neat_weekly_summaries
-- ============================================
DROP POLICY IF EXISTS neat_weekly_summaries_select_policy ON neat_weekly_summaries;
CREATE POLICY neat_weekly_summaries_select_policy ON neat_weekly_summaries
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_weekly_summaries_insert_policy ON neat_weekly_summaries;
CREATE POLICY neat_weekly_summaries_insert_policy ON neat_weekly_summaries
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_weekly_summaries_update_policy ON neat_weekly_summaries;
CREATE POLICY neat_weekly_summaries_update_policy ON neat_weekly_summaries
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_weekly_summaries_delete_policy ON neat_weekly_summaries;
CREATE POLICY neat_weekly_summaries_delete_policy ON neat_weekly_summaries
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS neat_weekly_summaries_service_policy ON neat_weekly_summaries;
CREATE POLICY neat_weekly_summaries_service_policy ON neat_weekly_summaries
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- Pre-seed NEAT achievements
-- ============================================
INSERT INTO neat_achievements (achievement_key, name, description, icon, requirement_type, requirement_value, tier, points, is_repeatable, sort_order) VALUES
-- Single Day Step Achievements
('first_5000_steps', 'First 5K', 'Walk 5,000 steps in a single day', '5K', 'single_day_steps', 5000, 'bronze', 25, TRUE, 1),
('steps_7500', 'Stepping Up', 'Walk 7,500 steps in a single day', '7K', 'single_day_steps', 7500, 'bronze', 35, TRUE, 2),
('steps_10000', '10K Club', 'Walk 10,000 steps in a single day', '10K', 'single_day_steps', 10000, 'silver', 50, TRUE, 3),
('steps_12500', 'Super Stepper', 'Walk 12,500 steps in a single day', '12K', 'single_day_steps', 12500, 'silver', 65, TRUE, 4),
('steps_15000', 'Marathon Walker', 'Walk 15,000 steps in a single day', '15K', 'single_day_steps', 15000, 'gold', 100, TRUE, 5),
('steps_20000', 'Ultra Walker', 'Walk 20,000 steps in a single day', '20K', 'single_day_steps', 20000, 'platinum', 150, TRUE, 6),
('steps_25000', 'Step Legend', 'Walk 25,000 steps in a single day', '25K', 'single_day_steps', 25000, 'diamond', 250, TRUE, 7),

-- Step Streak Achievements
('streak_steps_3', 'Three-peat', 'Meet your step goal 3 days in a row', '3D', 'streak_steps', 3, 'bronze', 30, TRUE, 10),
('streak_steps_7', 'Week Warrior', 'Meet your step goal 7 days in a row', '7D', 'streak_steps', 7, 'bronze', 50, TRUE, 11),
('streak_steps_14', 'Two Week Titan', 'Meet your step goal 14 days in a row', '14D', 'streak_steps', 14, 'silver', 100, TRUE, 12),
('streak_steps_30', 'Monthly Master', 'Meet your step goal 30 days in a row', '30D', 'streak_steps', 30, 'gold', 200, TRUE, 13),
('streak_steps_60', 'Iron Legs', 'Meet your step goal 60 days in a row', '60D', 'streak_steps', 60, 'platinum', 400, TRUE, 14),
('streak_steps_100', 'Century Walker', 'Meet your step goal 100 days in a row', '100', 'streak_steps', 100, 'diamond', 750, TRUE, 15),

-- Active Hours Achievements
('active_hours_8', 'Active Day', 'Have 8 active hours in a single day', '8H', 'single_day_active_hours', 8, 'bronze', 30, TRUE, 20),
('active_hours_10', 'Movement Master', 'Have 10 active hours in a single day', '10H', 'single_day_active_hours', 10, 'silver', 50, TRUE, 21),
('active_hours_12', 'All Day Active', 'Have 12 active hours in a single day', '12H', 'single_day_active_hours', 12, 'gold', 100, TRUE, 22),

-- Active Hours Streaks
('streak_active_7', 'Active Week', 'Have 10+ active hours for 7 days straight', 'AW', 'streak_active_hours', 7, 'silver', 75, TRUE, 25),
('streak_active_14', 'Active Fortnight', 'Have 10+ active hours for 14 days straight', 'AF', 'streak_active_hours', 14, 'gold', 150, TRUE, 26),
('streak_active_30', 'Active Month', 'Have 10+ active hours for 30 days straight', 'AM', 'streak_active_hours', 30, 'platinum', 300, TRUE, 27),

-- NEAT Score Achievements
('neat_score_80', 'NEAT Achiever', 'Score 80+ on your daily NEAT score', '80', 'streak_neat_score', 1, 'bronze', 25, TRUE, 30),
('streak_neat_7', 'NEAT Week', 'Score 80+ for 7 days in a row', 'N7', 'streak_neat_score', 7, 'silver', 100, TRUE, 31),
('streak_neat_30', 'NEAT Champion', 'Score 80+ for 30 days in a row', 'NC', 'streak_neat_score', 30, 'gold', 300, TRUE, 32),
('perfect_neat', 'Perfect NEAT', 'Score 100 on your daily NEAT score', '100', 'streak_neat_score', 0, 'platinum', 150, FALSE, 33),

-- Total Steps Milestones
('total_100k', '100K Total', 'Walk 100,000 total steps', '100K', 'total_steps', 100000, 'bronze', 50, FALSE, 40),
('total_500k', '500K Total', 'Walk 500,000 total steps', '500K', 'total_steps', 500000, 'silver', 100, FALSE, 41),
('total_1m', 'Millionaire', 'Walk 1,000,000 total steps', '1M', 'total_steps', 1000000, 'gold', 250, FALSE, 42),
('total_5m', '5 Million Club', 'Walk 5,000,000 total steps', '5M', 'total_steps', 5000000, 'platinum', 500, FALSE, 43),
('total_10m', 'Step Olympian', 'Walk 10,000,000 total steps', '10M', 'total_steps', 10000000, 'diamond', 1000, FALSE, 44),

-- Improvement Achievements
('improvement_25', 'Getting Better', 'Improve your average steps by 25% from baseline', '+25', 'improvement_percentage', 25, 'bronze', 50, FALSE, 50),
('improvement_50', 'Major Progress', 'Improve your average steps by 50% from baseline', '+50', 'improvement_percentage', 50, 'silver', 100, FALSE, 51),
('improvement_100', 'Doubled Up', 'Double your average steps from baseline', 'x2', 'improvement_percentage', 100, 'gold', 200, FALSE, 52),

-- Special Time-based Achievements
('early_bird', 'Early Bird', 'Complete 1000 steps before 7 AM', 'EB', 'early_bird', 1000, 'silver', 40, TRUE, 60),
('night_owl', 'Night Owl', 'Complete 1000 steps after 10 PM', 'NO', 'night_owl', 1000, 'silver', 40, TRUE, 61),

-- Consistency Achievements
('consistency_weekday', 'Workday Walker', 'Meet step goal all 5 weekdays', 'WW', 'consistency', 5, 'bronze', 50, TRUE, 70),
('consistency_weekend', 'Weekend Warrior', 'Meet step goal on both weekend days', 'WE', 'consistency', 2, 'bronze', 30, TRUE, 71),
('consistency_perfect_week', 'Perfect Week', 'Meet step goal all 7 days of the week', 'PW', 'consistency', 7, 'silver', 100, TRUE, 72)

ON CONFLICT (achievement_key) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    requirement_type = EXCLUDED.requirement_type,
    requirement_value = EXCLUDED.requirement_value,
    tier = EXCLUDED.tier,
    points = EXCLUDED.points,
    is_repeatable = EXCLUDED.is_repeatable,
    sort_order = EXCLUDED.sort_order;

-- ============================================
-- Function: Calculate NEAT score for a day
-- ============================================
CREATE OR REPLACE FUNCTION calculate_neat_score(
    p_user_id UUID,
    p_date DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_steps INTEGER;
    v_active_hours INTEGER;
    v_step_goal INTEGER;
    v_active_hours_goal INTEGER;
    v_step_score INTEGER;
    v_active_hours_score INTEGER;
    v_consistency_score INTEGER;
    v_final_score INTEGER;
    v_sedentary_penalty INTEGER;
    v_longest_sedentary INTEGER;
BEGIN
    -- Get user's step goal
    SELECT COALESCE(current_step_goal, 5000)
    INTO v_step_goal
    FROM neat_goals
    WHERE user_id = p_user_id AND goal_type = 'steps';

    IF v_step_goal IS NULL THEN
        v_step_goal := 5000;
    END IF;

    v_active_hours_goal := 10;

    -- Calculate totals from hourly data
    SELECT
        COALESCE(SUM(steps), 0),
        COALESCE(COUNT(*) FILTER (WHERE steps >= 250), 0),
        COALESCE(MAX(consecutive_sedentary), 0)
    INTO v_total_steps, v_active_hours, v_longest_sedentary
    FROM (
        SELECT
            steps,
            hour,
            COUNT(*) FILTER (WHERE steps < 250) OVER (ORDER BY hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) -
            COUNT(*) FILTER (WHERE steps >= 250) OVER (ORDER BY hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS consecutive_sedentary
        FROM neat_hourly_activity
        WHERE user_id = p_user_id AND activity_date = p_date
    ) hourly;

    -- Step score (0-40 points): Based on percentage of goal achieved, capped at 150%
    v_step_score := LEAST(40, ROUND((v_total_steps::NUMERIC / v_step_goal * 40))::INTEGER);

    -- Active hours score (0-35 points): Based on percentage of 10 active hours goal
    v_active_hours_score := LEAST(35, ROUND((v_active_hours::NUMERIC / v_active_hours_goal * 35))::INTEGER);

    -- Consistency score (0-25 points): Bonus for even distribution
    -- Penalize long sedentary stretches (more than 3 consecutive hours)
    IF v_longest_sedentary > 3 THEN
        v_sedentary_penalty := LEAST(15, (v_longest_sedentary - 3) * 5);
    ELSE
        v_sedentary_penalty := 0;
    END IF;

    -- Base consistency score
    IF v_active_hours >= 8 THEN
        v_consistency_score := 25;
    ELSIF v_active_hours >= 6 THEN
        v_consistency_score := 20;
    ELSIF v_active_hours >= 4 THEN
        v_consistency_score := 15;
    ELSE
        v_consistency_score := 10;
    END IF;

    v_consistency_score := GREATEST(0, v_consistency_score - v_sedentary_penalty);

    -- Calculate final score (0-100)
    v_final_score := v_step_score + v_active_hours_score + v_consistency_score;
    v_final_score := GREATEST(0, LEAST(100, v_final_score));

    RETURN v_final_score;
END;
$$;

COMMENT ON FUNCTION calculate_neat_score IS 'Calculates a 0-100 NEAT score based on steps, active hours, and consistency';

-- ============================================
-- Function: Get progressive step goal for user
-- ============================================
CREATE OR REPLACE FUNCTION get_progressive_step_goal(
    p_user_id UUID
)
RETURNS TABLE (
    current_goal INTEGER,
    next_goal INTEGER,
    days_until_increase INTEGER,
    baseline INTEGER,
    improvement_percent NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_goal INTEGER;
    v_increment INTEGER;
    v_baseline INTEGER;
    v_last_update DATE;
    v_max_goal INTEGER;
    v_streak INTEGER;
    v_days_at_goal INTEGER;
    v_avg_steps NUMERIC;
BEGIN
    -- Get user's goal settings
    SELECT
        COALESCE(ng.current_step_goal, 5000),
        COALESCE(ng.goal_increment, 500),
        ng.baseline_steps,
        ng.last_goal_update,
        COALESCE(ng.max_goal, 15000)
    INTO v_current_goal, v_increment, v_baseline, v_last_update, v_max_goal
    FROM neat_goals ng
    WHERE ng.user_id = p_user_id AND ng.goal_type = 'steps';

    -- Default if no goal exists
    IF v_current_goal IS NULL THEN
        v_current_goal := 5000;
        v_increment := 500;
        v_max_goal := 15000;
    END IF;

    -- Get current streak
    SELECT COALESCE(ns.current_streak, 0)
    INTO v_streak
    FROM neat_streaks ns
    WHERE ns.user_id = p_user_id AND ns.streak_type = 'steps';

    -- Calculate days since last goal update
    IF v_last_update IS NOT NULL THEN
        v_days_at_goal := CURRENT_DATE - v_last_update;
    ELSE
        v_days_at_goal := 0;
    END IF;

    -- Calculate average steps over last 7 days
    SELECT AVG(total_steps)
    INTO v_avg_steps
    FROM neat_daily_scores
    WHERE user_id = p_user_id
    AND score_date >= CURRENT_DATE - INTERVAL '7 days';

    -- Return values
    current_goal := v_current_goal;

    -- Calculate next goal (only increases if streak >= 7 and at current goal for 7+ days)
    IF v_current_goal < v_max_goal AND v_streak >= 7 THEN
        next_goal := LEAST(v_max_goal, v_current_goal + v_increment);
    ELSE
        next_goal := v_current_goal;
    END IF;

    -- Days until increase (7 days of streak needed)
    IF v_streak < 7 THEN
        days_until_increase := 7 - v_streak;
    ELSIF v_current_goal >= v_max_goal THEN
        days_until_increase := -1;  -- At max
    ELSE
        days_until_increase := 0;  -- Ready for increase
    END IF;

    baseline := v_baseline;

    -- Calculate improvement percentage
    IF v_baseline IS NOT NULL AND v_baseline > 0 AND v_avg_steps IS NOT NULL THEN
        improvement_percent := ROUND(((v_avg_steps - v_baseline) / v_baseline * 100)::NUMERIC, 1);
    ELSE
        improvement_percent := 0;
    END IF;

    RETURN NEXT;
END;
$$;

COMMENT ON FUNCTION get_progressive_step_goal IS 'Returns user current goal, next goal, and progress toward goal increase';

-- ============================================
-- Function: Update daily NEAT score
-- ============================================
CREATE OR REPLACE FUNCTION update_daily_neat_score(
    p_user_id UUID,
    p_date DATE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_steps INTEGER;
    v_active_hours INTEGER;
    v_sedentary_hours INTEGER;
    v_neat_score INTEGER;
    v_step_goal INTEGER;
    v_step_goal_achieved BOOLEAN;
    v_total_distance INTEGER;
    v_total_calories INTEGER;
    v_longest_active INTEGER;
    v_longest_sedentary INTEGER;
    v_peak_hour INTEGER;
    v_peak_steps INTEGER;
BEGIN
    -- Get step goal
    SELECT COALESCE(current_step_goal, 5000)
    INTO v_step_goal
    FROM neat_goals
    WHERE user_id = p_user_id AND goal_type = 'steps';

    IF v_step_goal IS NULL THEN
        v_step_goal := 5000;
    END IF;

    -- Calculate aggregates from hourly data
    SELECT
        COALESCE(SUM(steps), 0),
        COALESCE(COUNT(*) FILTER (WHERE steps >= 250), 0),
        COALESCE(COUNT(*) FILTER (WHERE steps < 250), 0),
        COALESCE(SUM(distance_meters), 0),
        COALESCE(SUM(calories_burned), 0)
    INTO v_total_steps, v_active_hours, v_sedentary_hours, v_total_distance, v_total_calories
    FROM neat_hourly_activity
    WHERE user_id = p_user_id AND activity_date = p_date;

    -- Get peak hour
    SELECT hour, steps
    INTO v_peak_hour, v_peak_steps
    FROM neat_hourly_activity
    WHERE user_id = p_user_id AND activity_date = p_date
    ORDER BY steps DESC
    LIMIT 1;

    -- Calculate NEAT score
    v_neat_score := calculate_neat_score(p_user_id, p_date);

    -- Check if step goal achieved
    v_step_goal_achieved := v_total_steps >= v_step_goal;

    -- Upsert daily score
    INSERT INTO neat_daily_scores (
        user_id, score_date, neat_score, total_steps, active_hours,
        sedentary_hours, step_goal_achieved, goal_at_time, active_hours_goal,
        total_distance_meters, total_calories_burned, peak_hour, peak_hour_steps,
        updated_at
    ) VALUES (
        p_user_id, p_date, v_neat_score, v_total_steps, v_active_hours,
        v_sedentary_hours, v_step_goal_achieved, v_step_goal, 10,
        v_total_distance, v_total_calories, v_peak_hour, v_peak_steps,
        NOW()
    )
    ON CONFLICT (user_id, score_date) DO UPDATE SET
        neat_score = v_neat_score,
        total_steps = v_total_steps,
        active_hours = v_active_hours,
        sedentary_hours = v_sedentary_hours,
        step_goal_achieved = v_step_goal_achieved,
        goal_at_time = v_step_goal,
        total_distance_meters = v_total_distance,
        total_calories_burned = v_total_calories,
        peak_hour = v_peak_hour,
        peak_hour_steps = v_peak_steps,
        updated_at = NOW();
END;
$$;

COMMENT ON FUNCTION update_daily_neat_score IS 'Calculates and upserts daily NEAT score from hourly activity data';

-- ============================================
-- Function: Update NEAT streaks
-- ============================================
CREATE OR REPLACE FUNCTION update_neat_streaks(
    p_user_id UUID,
    p_date DATE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_score_record RECORD;
    v_streak_type TEXT;
    v_achieved BOOLEAN;
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_last_date DATE;
    v_streak_start DATE;
BEGIN
    -- Get the daily score for this date
    SELECT * INTO v_score_record
    FROM neat_daily_scores
    WHERE user_id = p_user_id AND score_date = p_date;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Update each streak type
    FOR v_streak_type IN SELECT unnest(ARRAY['steps', 'active_hours', 'neat_score'])
    LOOP
        -- Determine if goal was achieved for this type
        CASE v_streak_type
            WHEN 'steps' THEN
                v_achieved := v_score_record.step_goal_achieved;
            WHEN 'active_hours' THEN
                v_achieved := v_score_record.active_hours >= 10;
            WHEN 'neat_score' THEN
                v_achieved := v_score_record.neat_score >= 80;
        END CASE;

        -- Get current streak info
        SELECT current_streak, longest_streak, last_achievement_date, streak_start_date
        INTO v_current_streak, v_longest_streak, v_last_date, v_streak_start
        FROM neat_streaks
        WHERE user_id = p_user_id AND streak_type = v_streak_type;

        -- Initialize if not found
        IF NOT FOUND THEN
            v_current_streak := 0;
            v_longest_streak := 0;
            v_last_date := NULL;
            v_streak_start := NULL;
        END IF;

        IF v_achieved THEN
            -- Check if this continues the streak (consecutive day)
            IF v_last_date IS NULL OR p_date = v_last_date + 1 THEN
                v_current_streak := v_current_streak + 1;
                IF v_streak_start IS NULL THEN
                    v_streak_start := p_date;
                END IF;
            ELSIF p_date > v_last_date + 1 THEN
                -- Gap in streak, reset
                v_current_streak := 1;
                v_streak_start := p_date;
            END IF;
            -- Same day update, don't change streak

            -- Update longest if needed
            IF v_current_streak > v_longest_streak THEN
                v_longest_streak := v_current_streak;
            END IF;

            v_last_date := p_date;
        ELSE
            -- Goal not achieved, reset streak
            IF v_last_date IS NOT NULL AND p_date > v_last_date THEN
                v_current_streak := 0;
                v_streak_start := NULL;
            END IF;
        END IF;

        -- Upsert streak record
        INSERT INTO neat_streaks (
            user_id, streak_type, current_streak, longest_streak,
            last_achievement_date, streak_start_date,
            reached_7_days, reached_14_days, reached_30_days,
            reached_60_days, reached_100_days, updated_at
        ) VALUES (
            p_user_id, v_streak_type, v_current_streak, v_longest_streak,
            v_last_date, v_streak_start,
            v_longest_streak >= 7, v_longest_streak >= 14, v_longest_streak >= 30,
            v_longest_streak >= 60, v_longest_streak >= 100, NOW()
        )
        ON CONFLICT (user_id, streak_type) DO UPDATE SET
            current_streak = v_current_streak,
            longest_streak = v_longest_streak,
            last_achievement_date = v_last_date,
            streak_start_date = v_streak_start,
            reached_7_days = v_longest_streak >= 7,
            reached_14_days = v_longest_streak >= 14,
            reached_30_days = v_longest_streak >= 30,
            reached_60_days = v_longest_streak >= 60,
            reached_100_days = v_longest_streak >= 100,
            updated_at = NOW();
    END LOOP;
END;
$$;

COMMENT ON FUNCTION update_neat_streaks IS 'Updates all NEAT streak types based on daily score';

-- ============================================
-- Trigger: Auto-update streaks when daily score is inserted/updated
-- ============================================
CREATE OR REPLACE FUNCTION trigger_update_neat_streaks()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM update_neat_streaks(NEW.user_id, NEW.score_date);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS neat_daily_scores_streak_trigger ON neat_daily_scores;
CREATE TRIGGER neat_daily_scores_streak_trigger
    AFTER INSERT OR UPDATE ON neat_daily_scores
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_neat_streaks();

-- ============================================
-- Function: Initialize NEAT goals for new user
-- ============================================
CREATE OR REPLACE FUNCTION initialize_neat_goals(
    p_user_id UUID,
    p_baseline_steps INTEGER DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_initial_goal INTEGER;
BEGIN
    -- Calculate initial goal based on baseline (if provided)
    IF p_baseline_steps IS NOT NULL THEN
        -- Set goal to 10% above baseline, rounded to nearest 500
        v_initial_goal := ROUND((p_baseline_steps * 1.1) / 500.0) * 500;
        v_initial_goal := GREATEST(3000, LEAST(10000, v_initial_goal));
    ELSE
        v_initial_goal := 5000;
    END IF;

    -- Insert step goal
    INSERT INTO neat_goals (user_id, goal_type, current_step_goal, baseline_steps, goal_increment)
    VALUES (p_user_id, 'steps', v_initial_goal, p_baseline_steps, 500)
    ON CONFLICT (user_id, goal_type) DO NOTHING;

    -- Insert active hours goal
    INSERT INTO neat_goals (user_id, goal_type, current_step_goal, baseline_steps, goal_increment)
    VALUES (p_user_id, 'active_hours', 10, NULL, 1)
    ON CONFLICT (user_id, goal_type) DO NOTHING;

    -- Insert NEAT score goal
    INSERT INTO neat_goals (user_id, goal_type, current_step_goal, baseline_steps, goal_increment)
    VALUES (p_user_id, 'neat_score', 80, NULL, 5)
    ON CONFLICT (user_id, goal_type) DO NOTHING;

    -- Initialize default reminder preferences
    INSERT INTO neat_reminder_preferences (user_id)
    VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    -- Initialize streak records
    INSERT INTO neat_streaks (user_id, streak_type)
    VALUES
        (p_user_id, 'steps'),
        (p_user_id, 'active_hours'),
        (p_user_id, 'neat_score'),
        (p_user_id, 'combined')
    ON CONFLICT (user_id, streak_type) DO NOTHING;
END;
$$;

COMMENT ON FUNCTION initialize_neat_goals IS 'Initializes all NEAT-related records for a new user';

-- ============================================
-- Function: Check and award achievements
-- ============================================
CREATE OR REPLACE FUNCTION check_neat_achievements(
    p_user_id UUID,
    p_date DATE
)
RETURNS TABLE (
    achievement_key TEXT,
    achievement_name TEXT,
    tier TEXT,
    points INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_achievement RECORD;
    v_daily_score RECORD;
    v_streak RECORD;
    v_total_steps BIGINT;
    v_earned BOOLEAN;
    v_trigger_value INTEGER;
BEGIN
    -- Get daily score
    SELECT * INTO v_daily_score
    FROM neat_daily_scores
    WHERE user_id = p_user_id AND score_date = p_date;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Get total steps
    SELECT COALESCE(SUM(total_steps), 0)
    INTO v_total_steps
    FROM neat_daily_scores
    WHERE user_id = p_user_id;

    -- Check each achievement
    FOR v_achievement IN SELECT * FROM neat_achievements ORDER BY sort_order
    LOOP
        v_earned := FALSE;
        v_trigger_value := NULL;

        CASE v_achievement.requirement_type
            WHEN 'single_day_steps' THEN
                IF v_daily_score.total_steps >= v_achievement.requirement_value THEN
                    v_earned := TRUE;
                    v_trigger_value := v_daily_score.total_steps;
                END IF;

            WHEN 'streak_steps' THEN
                SELECT current_streak INTO v_trigger_value
                FROM neat_streaks
                WHERE user_id = p_user_id AND streak_type = 'steps';

                IF v_trigger_value >= v_achievement.requirement_value THEN
                    v_earned := TRUE;
                END IF;

            WHEN 'streak_active_hours' THEN
                SELECT current_streak INTO v_trigger_value
                FROM neat_streaks
                WHERE user_id = p_user_id AND streak_type = 'active_hours';

                IF v_trigger_value >= v_achievement.requirement_value THEN
                    v_earned := TRUE;
                END IF;

            WHEN 'streak_neat_score' THEN
                SELECT current_streak INTO v_trigger_value
                FROM neat_streaks
                WHERE user_id = p_user_id AND streak_type = 'neat_score';

                IF v_trigger_value >= v_achievement.requirement_value THEN
                    v_earned := TRUE;
                END IF;

            WHEN 'single_day_active_hours' THEN
                IF v_daily_score.active_hours >= v_achievement.requirement_value THEN
                    v_earned := TRUE;
                    v_trigger_value := v_daily_score.active_hours;
                END IF;

            WHEN 'total_steps' THEN
                IF v_total_steps >= v_achievement.requirement_value THEN
                    v_earned := TRUE;
                    v_trigger_value := v_total_steps::INTEGER;
                END IF;

            ELSE
                -- Other types can be handled by application logic
                NULL;
        END CASE;

        -- Award achievement if earned and not already awarded (for non-repeatable)
        IF v_earned THEN
            -- Check if already earned
            IF v_achievement.is_repeatable THEN
                -- For repeatable, check if earned today
                IF NOT EXISTS (
                    SELECT 1 FROM user_neat_achievements
                    WHERE user_id = p_user_id
                    AND achievement_id = v_achievement.id
                    AND trigger_date = p_date
                ) THEN
                    INSERT INTO user_neat_achievements (
                        user_id, achievement_id, trigger_value, trigger_date
                    ) VALUES (
                        p_user_id, v_achievement.id, v_trigger_value, p_date
                    );

                    achievement_key := v_achievement.achievement_key;
                    achievement_name := v_achievement.name;
                    tier := v_achievement.tier;
                    points := v_achievement.points;
                    RETURN NEXT;
                END IF;
            ELSE
                -- For non-repeatable, check if ever earned
                IF NOT EXISTS (
                    SELECT 1 FROM user_neat_achievements
                    WHERE user_id = p_user_id
                    AND achievement_id = v_achievement.id
                ) THEN
                    INSERT INTO user_neat_achievements (
                        user_id, achievement_id, trigger_value, trigger_date
                    ) VALUES (
                        p_user_id, v_achievement.id, v_trigger_value, p_date
                    );

                    achievement_key := v_achievement.achievement_key;
                    achievement_name := v_achievement.name;
                    tier := v_achievement.tier;
                    points := v_achievement.points;
                    RETURN NEXT;
                END IF;
            END IF;
        END IF;
    END LOOP;
END;
$$;

COMMENT ON FUNCTION check_neat_achievements IS 'Checks and awards any newly earned NEAT achievements';

-- ============================================
-- View: User NEAT dashboard summary
-- ============================================
CREATE OR REPLACE VIEW neat_user_dashboard AS
SELECT
    u.id AS user_id,
    ng.current_step_goal,
    ng.baseline_steps,
    ng.goal_increment,
    nds.score_date AS latest_date,
    nds.neat_score AS latest_score,
    nds.total_steps AS latest_steps,
    nds.active_hours AS latest_active_hours,
    nds.step_goal_achieved AS goal_achieved_today,
    ns_steps.current_streak AS steps_streak,
    ns_steps.longest_streak AS steps_longest_streak,
    ns_active.current_streak AS active_hours_streak,
    ns_neat.current_streak AS neat_score_streak,
    (SELECT COUNT(*) FROM user_neat_achievements WHERE user_id = u.id) AS total_achievements,
    (SELECT COALESCE(SUM(na.points), 0)
     FROM user_neat_achievements una
     JOIN neat_achievements na ON una.achievement_id = na.id
     WHERE una.user_id = u.id) AS total_points
FROM users u
LEFT JOIN neat_goals ng ON ng.user_id = u.id AND ng.goal_type = 'steps'
LEFT JOIN neat_daily_scores nds ON nds.user_id = u.id AND nds.score_date = CURRENT_DATE
LEFT JOIN neat_streaks ns_steps ON ns_steps.user_id = u.id AND ns_steps.streak_type = 'steps'
LEFT JOIN neat_streaks ns_active ON ns_active.user_id = u.id AND ns_active.streak_type = 'active_hours'
LEFT JOIN neat_streaks ns_neat ON ns_neat.user_id = u.id AND ns_neat.streak_type = 'neat_score';

COMMENT ON VIEW neat_user_dashboard IS 'Aggregated view of user NEAT stats for dashboard display';

-- Grant access to the view
GRANT SELECT ON neat_user_dashboard TO authenticated;

-- ============================================
-- Grant execute permissions on functions
-- ============================================
GRANT EXECUTE ON FUNCTION calculate_neat_score TO authenticated;
GRANT EXECUTE ON FUNCTION get_progressive_step_goal TO authenticated;
GRANT EXECUTE ON FUNCTION update_daily_neat_score TO authenticated;
GRANT EXECUTE ON FUNCTION update_neat_streaks TO authenticated;
GRANT EXECUTE ON FUNCTION initialize_neat_goals TO authenticated;
GRANT EXECUTE ON FUNCTION check_neat_achievements TO authenticated;

-- ============================================
-- Add comments for documentation
-- ============================================
COMMENT ON TABLE neat_goals IS 'User NEAT improvement goals with progressive targeting';
COMMENT ON TABLE neat_hourly_activity IS 'Hourly step tracking for sedentary detection';
COMMENT ON TABLE neat_daily_scores IS 'Daily aggregated NEAT metrics and calculated score';
COMMENT ON TABLE neat_streaks IS 'Consecutive day streaks for NEAT goal types';
COMMENT ON TABLE neat_achievements IS 'Achievement badge definitions for gamification';
COMMENT ON TABLE user_neat_achievements IS 'User earned achievements junction table';
COMMENT ON TABLE neat_reminder_preferences IS 'User preferences for movement reminders';
COMMENT ON TABLE neat_weekly_summaries IS 'Weekly aggregated NEAT data for trends';
