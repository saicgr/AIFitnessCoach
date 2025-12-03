-- Migration: Milestones & Achievements System
-- Created: 2025-12-02
-- Purpose: Track user achievements like PRs, streaks, weight milestones, etc.

-- ============================================
-- achievement_types - Definition of all possible achievements
-- ============================================
CREATE TABLE IF NOT EXISTS achievement_types (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,  -- 'strength', 'consistency', 'weight', 'cardio', 'habit'
    icon VARCHAR(10) NOT NULL,  -- Emoji icon
    tier VARCHAR(20) DEFAULT 'bronze',  -- bronze, silver, gold, platinum
    points INTEGER DEFAULT 10,
    threshold_value FLOAT,  -- Value needed to unlock (e.g., 7 for 7-day streak)
    threshold_unit VARCHAR(20),  -- 'days', 'lbs', 'kg', 'workouts', etc.
    is_repeatable BOOLEAN DEFAULT false,  -- Can be earned multiple times
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE achievement_types IS 'Master list of all achievement definitions';

-- Insert default achievement types
INSERT INTO achievement_types (id, name, description, category, icon, tier, points, threshold_value, threshold_unit, is_repeatable) VALUES
-- Consistency Streaks
('streak_7_days', '7-Day Warrior', 'Complete workouts 7 days in a row', 'consistency', '🔥', 'bronze', 50, 7, 'days', true),
('streak_14_days', 'Two Week Champion', 'Complete workouts 14 days in a row', 'consistency', '🔥', 'silver', 100, 14, 'days', true),
('streak_30_days', 'Monthly Master', 'Complete workouts 30 days in a row', 'consistency', '🔥', 'gold', 250, 30, 'days', true),
('streak_60_days', 'Iron Will', 'Complete workouts 60 days in a row', 'consistency', '💪', 'platinum', 500, 60, 'days', true),
('streak_100_days', 'Century Club', 'Complete workouts 100 days in a row', 'consistency', '🏆', 'platinum', 1000, 100, 'days', true),

-- Workout Milestones
('workouts_10', 'Getting Started', 'Complete 10 workouts', 'consistency', '🎯', 'bronze', 25, 10, 'workouts', false),
('workouts_25', 'Building Momentum', 'Complete 25 workouts', 'consistency', '🎯', 'bronze', 50, 25, 'workouts', false),
('workouts_50', 'Halfway Hero', 'Complete 50 workouts', 'consistency', '🎯', 'silver', 100, 50, 'workouts', false),
('workouts_100', 'Century Lifter', 'Complete 100 workouts', 'consistency', '🎯', 'gold', 200, 100, 'workouts', false),
('workouts_250', 'Gym Veteran', 'Complete 250 workouts', 'consistency', '🎯', 'platinum', 500, 250, 'workouts', false),
('workouts_500', 'Fitness Legend', 'Complete 500 workouts', 'consistency', '👑', 'platinum', 1000, 500, 'workouts', false),

-- Strength PRs
('pr_bench', 'Bench Press PR', 'Set a new personal record on bench press', 'strength', '🏋️', 'gold', 100, NULL, NULL, true),
('pr_squat', 'Squat PR', 'Set a new personal record on squat', 'strength', '🏋️', 'gold', 100, NULL, NULL, true),
('pr_deadlift', 'Deadlift PR', 'Set a new personal record on deadlift', 'strength', '🏋️', 'gold', 100, NULL, NULL, true),
('pr_any', 'New Personal Best', 'Set a new personal record on any exercise', 'strength', '⭐', 'silver', 50, NULL, NULL, true),

-- Weight Milestones (these will be checked relative to user's starting weight)
('weight_lost_5', 'First Steps', 'Lose 5 lbs from starting weight', 'weight', '⚖️', 'bronze', 50, 5, 'lbs', false),
('weight_lost_10', 'Double Digits', 'Lose 10 lbs from starting weight', 'weight', '⚖️', 'silver', 100, 10, 'lbs', false),
('weight_lost_20', 'Transformation', 'Lose 20 lbs from starting weight', 'weight', '⚖️', 'gold', 200, 20, 'lbs', false),
('weight_lost_50', 'Total Makeover', 'Lose 50 lbs from starting weight', 'weight', '⚖️', 'platinum', 500, 50, 'lbs', false),
('weight_gained_5', 'Bulk Begun', 'Gain 5 lbs of muscle', 'weight', '💪', 'bronze', 50, 5, 'lbs', false),
('weight_gained_10', 'Serious Gains', 'Gain 10 lbs of muscle', 'weight', '💪', 'silver', 100, 10, 'lbs', false),

-- Cardio Achievements
('run_5k', '5K Finisher', 'Complete a 5K run', 'cardio', '🏃', 'bronze', 50, 5, 'km', true),
('run_10k', '10K Warrior', 'Complete a 10K run', 'cardio', '🏃', 'silver', 100, 10, 'km', true),
('run_half_marathon', 'Half Marathon Hero', 'Complete a half marathon', 'cardio', '🏃', 'gold', 250, 21.1, 'km', true),
('run_marathon', 'Marathon Legend', 'Complete a marathon', 'cardio', '🏃', 'platinum', 500, 42.2, 'km', true),

-- Habit Streaks
('hydration_7_days', 'Hydration Hero', 'Meet hydration goal 7 days in a row', 'habit', '💧', 'bronze', 30, 7, 'days', true),
('protein_7_days', 'Protein Pro', 'Meet protein goal 7 days in a row', 'habit', '🥩', 'bronze', 30, 7, 'days', true),
('sleep_7_days', 'Sleep Champion', 'Get 7+ hours of sleep for 7 days', 'habit', '😴', 'bronze', 30, 7, 'days', true),

-- Special Achievements
('first_workout', 'Day One', 'Complete your first workout', 'consistency', '🌟', 'bronze', 25, 1, 'workouts', false),
('early_bird', 'Early Bird', 'Complete a workout before 6 AM', 'consistency', '🌅', 'silver', 25, NULL, NULL, true),
('night_owl', 'Night Owl', 'Complete a workout after 10 PM', 'consistency', '🌙', 'silver', 25, NULL, NULL, true),
('weekend_warrior', 'Weekend Warrior', 'Complete workouts on both Saturday and Sunday', 'consistency', '⚡', 'silver', 50, NULL, NULL, true),
('perfect_week', 'Perfect Week', 'Complete all scheduled workouts in a week', 'consistency', '✨', 'gold', 75, NULL, NULL, true)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- user_achievements - Earned achievements per user
-- ============================================
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id VARCHAR(50) NOT NULL REFERENCES achievement_types(id) ON DELETE CASCADE,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    trigger_value FLOAT,  -- The value that triggered the achievement (e.g., weight lifted)
    trigger_details JSONB,  -- Additional context (e.g., exercise name, streak count)
    is_notified BOOLEAN DEFAULT false,  -- Whether user has been notified
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_achievements IS 'Tracks which achievements each user has earned';
COMMENT ON COLUMN user_achievements.trigger_value IS 'The value that triggered the achievement';
COMMENT ON COLUMN user_achievements.trigger_details IS 'Additional context like exercise name, workout id, etc.';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_earned_at ON user_achievements(earned_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_achievements_is_notified ON user_achievements(is_notified);

-- Enable Row Level Security
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Users can only see their own achievements
DROP POLICY IF EXISTS user_achievements_select_policy ON user_achievements;
CREATE POLICY user_achievements_select_policy ON user_achievements
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS user_achievements_service_policy ON user_achievements;
CREATE POLICY user_achievements_service_policy ON user_achievements
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- user_streaks - Track current streaks
-- ============================================
CREATE TABLE IF NOT EXISTS user_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    streak_type VARCHAR(50) NOT NULL,  -- 'workout', 'hydration', 'protein', 'sleep'
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    streak_start_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, streak_type)
);

COMMENT ON TABLE user_streaks IS 'Tracks current and longest streaks for various activities';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_streaks_user_id ON user_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_user_streaks_type ON user_streaks(streak_type);

-- Enable Row Level Security
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;

-- Users can only see their own streaks
DROP POLICY IF EXISTS user_streaks_select_policy ON user_streaks;
CREATE POLICY user_streaks_select_policy ON user_streaks
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS user_streaks_service_policy ON user_streaks;
CREATE POLICY user_streaks_service_policy ON user_streaks
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- personal_records - Track PRs per exercise
-- ============================================
CREATE TABLE IF NOT EXISTS personal_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    record_type VARCHAR(20) NOT NULL,  -- 'weight', 'reps', 'time', 'distance'
    record_value FLOAT NOT NULL,
    record_unit VARCHAR(20) NOT NULL,  -- 'lbs', 'kg', 'reps', 'seconds', 'km', 'miles'
    previous_value FLOAT,
    improvement_percentage FLOAT,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE personal_records IS 'Tracks personal records for each exercise';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_personal_records_user_id ON personal_records(user_id);
CREATE INDEX IF NOT EXISTS idx_personal_records_exercise_name ON personal_records(exercise_name);
CREATE INDEX IF NOT EXISTS idx_personal_records_achieved_at ON personal_records(achieved_at DESC);

-- Unique constraint to ensure one record per exercise/type combo (latest is the PR)
CREATE UNIQUE INDEX IF NOT EXISTS idx_personal_records_unique
ON personal_records(user_id, exercise_name, record_type);

-- Enable Row Level Security
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

-- Users can only see their own records
DROP POLICY IF EXISTS personal_records_select_policy ON personal_records;
CREATE POLICY personal_records_select_policy ON personal_records
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS personal_records_service_policy ON personal_records;
CREATE POLICY personal_records_service_policy ON personal_records
    FOR ALL
    USING (auth.role() = 'service_role');
