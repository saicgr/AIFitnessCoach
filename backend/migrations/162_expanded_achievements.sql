-- Migration: Expanded Achievement System
-- Created: 2025-01-19
-- Purpose: Add tier progression, new achievement categories, and 360+ trophies

-- ============================================
-- Update achievement_types table with new columns
-- ============================================
ALTER TABLE achievement_types
ADD COLUMN IF NOT EXISTS tier_level INT DEFAULT 1,  -- 1=Bronze, 2=Silver, 3=Gold, 4=Platinum
ADD COLUMN IF NOT EXISTS parent_achievement_id VARCHAR(50) REFERENCES achievement_types(id),  -- For tier chains
ADD COLUMN IF NOT EXISTS rarity TEXT DEFAULT 'common',  -- common, uncommon, rare, epic, legendary
ADD COLUMN IF NOT EXISTS is_secret BOOLEAN DEFAULT FALSE,  -- Show as "???" until earned
ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT FALSE,  -- Completely hidden until earned
ADD COLUMN IF NOT EXISTS hint_text TEXT,  -- Clue for secret achievements
ADD COLUMN IF NOT EXISTS xp_reward INT DEFAULT 0,  -- XP awarded when earned
ADD COLUMN IF NOT EXISTS merch_reward TEXT,  -- 'tshirt', 'hoodie', etc. if applicable
ADD COLUMN IF NOT EXISTS unlock_animation TEXT DEFAULT 'standard',  -- Animation type on unlock
ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;  -- Display order within category

-- Update existing achievements with tier_level and xp_reward
UPDATE achievement_types SET tier_level = 1, xp_reward = 50 WHERE tier = 'bronze';
UPDATE achievement_types SET tier_level = 2, xp_reward = 100 WHERE tier = 'silver';
UPDATE achievement_types SET tier_level = 3, xp_reward = 250 WHERE tier = 'gold';
UPDATE achievement_types SET tier_level = 4, xp_reward = 1000 WHERE tier = 'platinum';

-- ============================================
-- A. EXERCISE MASTERY (48 trophies)
-- ============================================

-- Chest Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('chest_bronze', 'Chest Beginner', 'Complete 25 chest exercises', 'exercise_mastery', '🏋️', 'bronze', 1, 50, 25, 'chest_exercises', 50, 1),
('chest_silver', 'Chest Builder', 'Complete 100 chest exercises', 'exercise_mastery', '🏋️', 'silver', 2, 100, 100, 'chest_exercises', 100, 2),
('chest_gold', 'Chest Champion', 'Complete 500 chest exercises', 'exercise_mastery', '🏋️', 'gold', 3, 250, 500, 'chest_exercises', 250, 3),
('chest_platinum', 'Chest Legend', 'Complete 2,000 chest exercises', 'exercise_mastery', '🏋️', 'platinum', 4, 1000, 2000, 'chest_exercises', 1000, 4)
ON CONFLICT (id) DO UPDATE SET
    tier_level = EXCLUDED.tier_level,
    xp_reward = EXCLUDED.xp_reward,
    sort_order = EXCLUDED.sort_order;

-- Back Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('back_bronze', 'Back Beginner', 'Complete 25 back exercises', 'exercise_mastery', '🏋️', 'bronze', 1, 50, 25, 'back_exercises', 50, 5),
('back_silver', 'Back Builder', 'Complete 100 back exercises', 'exercise_mastery', '🏋️', 'silver', 2, 100, 100, 'back_exercises', 100, 6),
('back_gold', 'Back Champion', 'Complete 500 back exercises', 'exercise_mastery', '🏋️', 'gold', 3, 250, 500, 'back_exercises', 250, 7),
('back_platinum', 'Back Legend', 'Complete 2,000 back exercises', 'exercise_mastery', '🏋️', 'platinum', 4, 1000, 2000, 'back_exercises', 1000, 8)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Shoulders Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('shoulders_bronze', 'Shoulders Beginner', 'Complete 25 shoulder exercises', 'exercise_mastery', '🏋️', 'bronze', 1, 50, 25, 'shoulders_exercises', 50, 9),
('shoulders_silver', 'Shoulders Builder', 'Complete 100 shoulder exercises', 'exercise_mastery', '🏋️', 'silver', 2, 100, 100, 'shoulders_exercises', 100, 10),
('shoulders_gold', 'Shoulders Champion', 'Complete 500 shoulder exercises', 'exercise_mastery', '🏋️', 'gold', 3, 250, 500, 'shoulders_exercises', 250, 11),
('shoulders_platinum', 'Shoulders Legend', 'Complete 2,000 shoulder exercises', 'exercise_mastery', '🏋️', 'platinum', 4, 1000, 2000, 'shoulders_exercises', 1000, 12)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Biceps Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('biceps_bronze', 'Biceps Beginner', 'Complete 25 bicep exercises', 'exercise_mastery', '💪', 'bronze', 1, 50, 25, 'biceps_exercises', 50, 13),
('biceps_silver', 'Biceps Builder', 'Complete 100 bicep exercises', 'exercise_mastery', '💪', 'silver', 2, 100, 100, 'biceps_exercises', 100, 14),
('biceps_gold', 'Biceps Champion', 'Complete 500 bicep exercises', 'exercise_mastery', '💪', 'gold', 3, 250, 500, 'biceps_exercises', 250, 15),
('biceps_platinum', 'Biceps Legend', 'Complete 2,000 bicep exercises', 'exercise_mastery', '💪', 'platinum', 4, 1000, 2000, 'biceps_exercises', 1000, 16)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Triceps Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('triceps_bronze', 'Triceps Beginner', 'Complete 25 tricep exercises', 'exercise_mastery', '💪', 'bronze', 1, 50, 25, 'triceps_exercises', 50, 17),
('triceps_silver', 'Triceps Builder', 'Complete 100 tricep exercises', 'exercise_mastery', '💪', 'silver', 2, 100, 100, 'triceps_exercises', 100, 18),
('triceps_gold', 'Triceps Champion', 'Complete 500 tricep exercises', 'exercise_mastery', '💪', 'gold', 3, 250, 500, 'triceps_exercises', 250, 19),
('triceps_platinum', 'Triceps Legend', 'Complete 2,000 tricep exercises', 'exercise_mastery', '💪', 'platinum', 4, 1000, 2000, 'triceps_exercises', 1000, 20)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Legs Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('legs_bronze', 'Legs Beginner', 'Complete 25 leg exercises', 'exercise_mastery', '🦵', 'bronze', 1, 50, 25, 'legs_exercises', 50, 21),
('legs_silver', 'Legs Builder', 'Complete 100 leg exercises', 'exercise_mastery', '🦵', 'silver', 2, 100, 100, 'legs_exercises', 100, 22),
('legs_gold', 'Legs Champion', 'Complete 500 leg exercises', 'exercise_mastery', '🦵', 'gold', 3, 250, 500, 'legs_exercises', 250, 23),
('legs_platinum', 'Legs Legend', 'Complete 2,000 leg exercises', 'exercise_mastery', '🦵', 'platinum', 4, 1000, 2000, 'legs_exercises', 1000, 24)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Core Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('core_bronze', 'Core Beginner', 'Complete 25 core exercises', 'exercise_mastery', '🎯', 'bronze', 1, 50, 25, 'core_exercises', 50, 25),
('core_silver', 'Core Builder', 'Complete 100 core exercises', 'exercise_mastery', '🎯', 'silver', 2, 100, 100, 'core_exercises', 100, 26),
('core_gold', 'Core Champion', 'Complete 500 core exercises', 'exercise_mastery', '🎯', 'gold', 3, 250, 500, 'core_exercises', 250, 27),
('core_platinum', 'Core Legend', 'Complete 2,000 core exercises', 'exercise_mastery', '🎯', 'platinum', 4, 1000, 2000, 'core_exercises', 1000, 28)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Glutes Mastery
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('glutes_bronze', 'Glutes Beginner', 'Complete 25 glute exercises', 'exercise_mastery', '🍑', 'bronze', 1, 50, 25, 'glutes_exercises', 50, 29),
('glutes_silver', 'Glutes Builder', 'Complete 100 glute exercises', 'exercise_mastery', '🍑', 'silver', 2, 100, 100, 'glutes_exercises', 100, 30),
('glutes_gold', 'Glutes Champion', 'Complete 500 glute exercises', 'exercise_mastery', '🍑', 'gold', 3, 250, 500, 'glutes_exercises', 250, 31),
('glutes_platinum', 'Glutes Legend', 'Complete 2,000 glute exercises', 'exercise_mastery', '🍑', 'platinum', 4, 1000, 2000, 'glutes_exercises', 1000, 32)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Squat Specialist
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('squat_bronze', 'Squat Novice', 'Complete 50 squat sets', 'exercise_mastery', '🦵', 'bronze', 1, 50, 50, 'squat_sets', 50, 33),
('squat_silver', 'Squat Enthusiast', 'Complete 250 squat sets', 'exercise_mastery', '🦵', 'silver', 2, 100, 250, 'squat_sets', 100, 34),
('squat_gold', 'Squat Expert', 'Complete 1,000 squat sets', 'exercise_mastery', '🦵', 'gold', 3, 250, 1000, 'squat_sets', 250, 35),
('squat_platinum', 'Squat Master', 'Complete 5,000 squat sets', 'exercise_mastery', '🦵', 'platinum', 4, 1000, 5000, 'squat_sets', 1000, 36)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Deadlift Specialist
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('deadlift_bronze', 'Deadlift Novice', 'Complete 50 deadlift sets', 'exercise_mastery', '🏋️', 'bronze', 1, 50, 50, 'deadlift_sets', 50, 37),
('deadlift_silver', 'Deadlift Enthusiast', 'Complete 250 deadlift sets', 'exercise_mastery', '🏋️', 'silver', 2, 100, 250, 'deadlift_sets', 100, 38),
('deadlift_gold', 'Deadlift Expert', 'Complete 1,000 deadlift sets', 'exercise_mastery', '🏋️', 'gold', 3, 250, 1000, 'deadlift_sets', 250, 39),
('deadlift_platinum', 'Deadlift Master', 'Complete 5,000 deadlift sets', 'exercise_mastery', '🏋️', 'platinum', 4, 1000, 5000, 'deadlift_sets', 1000, 40)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Bench Press Specialist
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('bench_bronze', 'Bench Novice', 'Complete 50 bench press sets', 'exercise_mastery', '🏋️', 'bronze', 1, 50, 50, 'bench_sets', 50, 41),
('bench_silver', 'Bench Enthusiast', 'Complete 250 bench press sets', 'exercise_mastery', '🏋️', 'silver', 2, 100, 250, 'bench_sets', 100, 42),
('bench_gold', 'Bench Expert', 'Complete 1,000 bench press sets', 'exercise_mastery', '🏋️', 'gold', 3, 250, 1000, 'bench_sets', 250, 43),
('bench_platinum', 'Bench Master', 'Complete 5,000 bench press sets', 'exercise_mastery', '🏋️', 'platinum', 4, 1000, 5000, 'bench_sets', 1000, 44)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- OHP Specialist
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('ohp_bronze', 'OHP Novice', 'Complete 50 overhead press sets', 'exercise_mastery', '🏋️', 'bronze', 1, 50, 50, 'ohp_sets', 50, 45),
('ohp_silver', 'OHP Enthusiast', 'Complete 250 overhead press sets', 'exercise_mastery', '🏋️', 'silver', 2, 100, 250, 'ohp_sets', 100, 46),
('ohp_gold', 'OHP Expert', 'Complete 1,000 overhead press sets', 'exercise_mastery', '🏋️', 'gold', 3, 250, 1000, 'ohp_sets', 250, 47),
('ohp_platinum', 'OHP Master', 'Complete 5,000 overhead press sets', 'exercise_mastery', '🏋️', 'platinum', 4, 1000, 5000, 'ohp_sets', 1000, 48)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- B. VOLUME ACHIEVEMENTS (20 trophies)
-- ============================================

-- Weight Lifted Lifetime
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('volume_weight_bronze', 'Iron Starter', 'Lift 25,000 lbs total', 'volume', '⚖️', 'bronze', 1, 50, 25000, 'lbs_lifted', 50, 49),
('volume_weight_silver', 'Iron Mover', 'Lift 250,000 lbs total', 'volume', '⚖️', 'silver', 2, 100, 250000, 'lbs_lifted', 100, 50),
('volume_weight_gold', 'Million Pound Club', 'Lift 1,000,000 lbs total', 'volume', '⚖️', 'gold', 3, 500, 1000000, 'lbs_lifted', 500, 51),
('volume_weight_platinum', '5 Million Pound Club', 'Lift 5,000,000 lbs total', 'volume', '⚖️', 'platinum', 4, 2000, 5000000, 'lbs_lifted', 2000, 52)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Sets Completed
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('volume_sets_bronze', 'Set Starter', 'Complete 500 sets', 'volume', '📊', 'bronze', 1, 50, 500, 'sets', 50, 53),
('volume_sets_silver', 'Set Builder', 'Complete 5,000 sets', 'volume', '📊', 'silver', 2, 100, 5000, 'sets', 100, 54),
('volume_sets_gold', 'Set Machine', 'Complete 25,000 sets', 'volume', '📊', 'gold', 3, 250, 25000, 'sets', 250, 55),
('volume_sets_platinum', 'Set Legend', 'Complete 100,000 sets', 'volume', '📊', 'platinum', 4, 1000, 100000, 'sets', 1000, 56)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Reps Completed
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('volume_reps_bronze', 'Rep Rookie', 'Complete 5,000 reps', 'volume', '🔢', 'bronze', 1, 50, 5000, 'reps', 50, 57),
('volume_reps_silver', 'Rep Regular', 'Complete 50,000 reps', 'volume', '🔢', 'silver', 2, 100, 50000, 'reps', 100, 58),
('volume_reps_gold', 'Rep Machine', 'Complete 250,000 reps', 'volume', '🔢', 'gold', 3, 250, 250000, 'reps', 250, 59),
('volume_reps_platinum', 'Million Rep Club', 'Complete 1,000,000 reps', 'volume', '🔢', 'platinum', 4, 1000, 1000000, 'reps', 1000, 60)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Exercises Performed
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('volume_exercises_bronze', 'Exercise Explorer', 'Perform 500 exercises', 'volume', '🏃', 'bronze', 1, 50, 500, 'exercises', 50, 61),
('volume_exercises_silver', 'Exercise Enthusiast', 'Perform 2,500 exercises', 'volume', '🏃', 'silver', 2, 100, 2500, 'exercises', 100, 62),
('volume_exercises_gold', 'Exercise Expert', 'Perform 10,000 exercises', 'volume', '🏃', 'gold', 3, 250, 10000, 'exercises', 250, 63),
('volume_exercises_platinum', 'Exercise Encyclopedia', 'Perform 50,000 exercises', 'volume', '🏃', 'platinum', 4, 1000, 50000, 'exercises', 1000, 64)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Unique Exercises
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('volume_unique_bronze', 'Variety Seeker', 'Try 25 unique exercises', 'volume', '🎯', 'bronze', 1, 50, 25, 'unique_exercises', 50, 65),
('volume_unique_silver', 'Variety Lover', 'Try 75 unique exercises', 'volume', '🎯', 'silver', 2, 100, 75, 'unique_exercises', 100, 66),
('volume_unique_gold', 'Variety Master', 'Try 150 unique exercises', 'volume', '🎯', 'gold', 3, 250, 150, 'unique_exercises', 250, 67),
('volume_unique_platinum', 'Exercise Collector', 'Try 300 unique exercises', 'volume', '🎯', 'platinum', 4, 500, 300, 'unique_exercises', 500, 68)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- C. TIME ACHIEVEMENTS (16 trophies)
-- ============================================

-- Total Workout Time
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('time_total_bronze', 'Time Starter', '10 hours total workout time', 'time', '⏱️', 'bronze', 1, 50, 10, 'hours', 50, 69),
('time_total_silver', 'Time Investor', '50 hours total workout time', 'time', '⏱️', 'silver', 2, 100, 50, 'hours', 100, 70),
('time_total_gold', 'Time Dedicated', '250 hours total workout time', 'time', '⏱️', 'gold', 3, 250, 250, 'hours', 250, 71),
('time_total_platinum', '1000 Hour Club', '1,000 hours total workout time', 'time', '⏱️', 'platinum', 4, 1000, 1000, 'hours', 1000, 72)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Single Workout Duration
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('time_single_bronze', 'Quick Session', 'Complete 30-minute workout', 'time', '🕐', 'bronze', 1, 25, 30, 'minutes_single', 25, 73),
('time_single_silver', 'Solid Session', 'Complete 60-minute workout', 'time', '🕐', 'silver', 2, 50, 60, 'minutes_single', 50, 74),
('time_single_gold', 'Extended Session', 'Complete 90-minute workout', 'time', '🕐', 'gold', 3, 100, 90, 'minutes_single', 100, 75),
('time_single_platinum', 'Marathon Session', 'Complete 2-hour workout', 'time', '🕐', 'platinum', 4, 200, 120, 'minutes_single', 200, 76)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Early Bird
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('time_early_bronze', 'Early Riser', '5 workouts before 6 AM', 'time', '🌅', 'bronze', 1, 50, 5, 'early_workouts', 50, 77),
('time_early_silver', 'Dawn Patrol', '25 workouts before 6 AM', 'time', '🌅', 'silver', 2, 100, 25, 'early_workouts', 100, 78),
('time_early_gold', 'Sunrise Warrior', '100 workouts before 6 AM', 'time', '🌅', 'gold', 3, 250, 100, 'early_workouts', 250, 79),
('time_early_platinum', 'Early Bird Legend', '365 workouts before 6 AM', 'time', '🌅', 'platinum', 4, 1000, 365, 'early_workouts', 1000, 80)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Night Owl
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('time_night_bronze', 'Night Starter', '5 workouts after 10 PM', 'time', '🌙', 'bronze', 1, 50, 5, 'night_workouts', 50, 81),
('time_night_silver', 'Night Regular', '25 workouts after 10 PM', 'time', '🌙', 'silver', 2, 100, 25, 'night_workouts', 100, 82),
('time_night_gold', 'Night Warrior', '100 workouts after 10 PM', 'time', '🌙', 'gold', 3, 250, 100, 'night_workouts', 250, 83),
('time_night_platinum', 'Night Owl Legend', '365 workouts after 10 PM', 'time', '🌙', 'platinum', 4, 1000, 365, 'night_workouts', 1000, 84)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- D. CONSISTENCY ACHIEVEMENTS (24 trophies)
-- ============================================

-- Daily Streak
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_repeatable) VALUES
('streak_daily_bronze', 'Week Warrior', '7-day workout streak', 'consistency', '🔥', 'bronze', 1, 50, 7, 'streak_days', 50, 85, true),
('streak_daily_silver', 'Month Master', '30-day workout streak', 'consistency', '🔥', 'silver', 2, 100, 30, 'streak_days', 100, 86, true),
('streak_daily_gold', 'Half Year Hero', '180-day workout streak', 'consistency', '🔥', 'gold', 3, 500, 180, 'streak_days', 500, 87, true),
('streak_daily_platinum', '2-Year Legend', '730-day workout streak', 'consistency', '🔥', 'platinum', 4, 2000, 730, 'streak_days', 2000, 88, true)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Weekly Streak (3+ workouts/week)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_repeatable) VALUES
('streak_weekly_bronze', 'Consistent Month', '4 weeks with 3+ workouts', 'consistency', '📅', 'bronze', 1, 50, 4, 'weekly_streak', 50, 89, true),
('streak_weekly_silver', 'Consistent Half', '26 weeks with 3+ workouts', 'consistency', '📅', 'silver', 2, 100, 26, 'weekly_streak', 100, 90, true),
('streak_weekly_gold', 'Consistent Year', '52 weeks with 3+ workouts', 'consistency', '📅', 'gold', 3, 500, 52, 'weekly_streak', 500, 91, true),
('streak_weekly_platinum', 'Consistent Legend', '156 weeks with 3+ workouts', 'consistency', '📅', 'platinum', 4, 2000, 156, 'weekly_streak', 2000, 92, true)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Monthly Active (15+ workouts/month)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('active_monthly_bronze', 'Active Quarter', '3 months with 15+ workouts each', 'consistency', '📆', 'bronze', 1, 50, 3, 'active_months', 50, 93),
('active_monthly_silver', 'Active Year', '12 months with 15+ workouts each', 'consistency', '📆', 'silver', 2, 200, 12, 'active_months', 200, 94),
('active_monthly_gold', 'Active Veteran', '24 months with 15+ workouts each', 'consistency', '📆', 'gold', 3, 500, 24, 'active_months', 500, 95),
('active_monthly_platinum', 'Active Legend', '60 months with 15+ workouts each', 'consistency', '📆', 'platinum', 4, 2000, 60, 'active_months', 2000, 96)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Perfect Week (hit all scheduled)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_repeatable) VALUES
('perfect_week_bronze', 'Perfect Month', '4 perfect weeks', 'consistency', '✨', 'bronze', 1, 50, 4, 'perfect_weeks', 50, 97, true),
('perfect_week_silver', 'Perfect Quarter', '12 perfect weeks', 'consistency', '✨', 'silver', 2, 150, 12, 'perfect_weeks', 150, 98, true),
('perfect_week_gold', 'Perfect Year', '52 perfect weeks', 'consistency', '✨', 'gold', 3, 500, 52, 'perfect_weeks', 500, 99, true),
('perfect_week_platinum', 'Perfect Legend', '156 perfect weeks', 'consistency', '✨', 'platinum', 4, 2000, 156, 'perfect_weeks', 2000, 100, true)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Workout Count
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('workouts_bronze', 'Getting Started', 'Complete 25 workouts', 'consistency', '🎯', 'bronze', 1, 50, 25, 'workouts', 50, 101),
('workouts_silver', 'Building Habit', 'Complete 100 workouts', 'consistency', '🎯', 'silver', 2, 100, 100, 'workouts', 100, 102),
('workouts_gold', 'Gym Regular', 'Complete 500 workouts', 'consistency', '🎯', 'gold', 3, 300, 500, 'workouts', 300, 103),
('workouts_platinum', 'Fitness Legend', 'Complete 2,000 workouts', 'consistency', '🎯', 'platinum', 4, 1500, 2000, 'workouts', 1500, 104)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Weekend Warrior
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_repeatable) VALUES
('weekend_bronze', 'Weekend Starter', '4 complete weekends', 'consistency', '⚡', 'bronze', 1, 50, 4, 'complete_weekends', 50, 105, true),
('weekend_silver', 'Weekend Regular', '25 complete weekends', 'consistency', '⚡', 'silver', 2, 100, 25, 'complete_weekends', 100, 106, true),
('weekend_gold', 'Weekend Champion', '52 complete weekends', 'consistency', '⚡', 'gold', 3, 250, 52, 'complete_weekends', 250, 107, true),
('weekend_platinum', 'Weekend Legend', '200 complete weekends', 'consistency', '⚡', 'platinum', 4, 1000, 200, 'complete_weekends', 1000, 108, true)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- E. PERSONAL RECORDS ACHIEVEMENTS (32 trophies)
-- ============================================

-- PR Count
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_count_bronze', 'PR Starter', 'Set 10 personal records', 'personal_records', '🏆', 'bronze', 1, 50, 10, 'prs', 50, 109),
('pr_count_silver', 'PR Hunter', 'Set 50 personal records', 'personal_records', '🏆', 'silver', 2, 100, 50, 'prs', 100, 110),
('pr_count_gold', 'PR Machine', 'Set 200 personal records', 'personal_records', '🏆', 'gold', 3, 250, 200, 'prs', 250, 111),
('pr_count_platinum', 'PR Legend', 'Set 500 personal records', 'personal_records', '🏆', 'platinum', 4, 1000, 500, 'prs', 1000, 112)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- PR Streak
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_streak_bronze', 'PR Momentum', '3 workouts in a row with PRs', 'personal_records', '⚡', 'bronze', 1, 75, 3, 'pr_streak', 75, 113),
('pr_streak_silver', 'PR Fire', '7 workouts in a row with PRs', 'personal_records', '⚡', 'silver', 2, 150, 7, 'pr_streak', 150, 114),
('pr_streak_gold', 'PR Blaze', '14 workouts in a row with PRs', 'personal_records', '⚡', 'gold', 3, 300, 14, 'pr_streak', 300, 115),
('pr_streak_platinum', 'PR Inferno', '30 workouts in a row with PRs', 'personal_records', '⚡', 'platinum', 4, 1000, 30, 'pr_streak', 1000, 116)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Bench PRs
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_bench_bronze', 'Bench Progressor', '5 bench press PRs', 'personal_records', '🏋️', 'bronze', 1, 50, 5, 'bench_prs', 50, 117),
('pr_bench_silver', 'Bench Builder', '15 bench press PRs', 'personal_records', '🏋️', 'silver', 2, 100, 15, 'bench_prs', 100, 118),
('pr_bench_gold', 'Bench Beast', '30 bench press PRs', 'personal_records', '🏋️', 'gold', 3, 250, 30, 'bench_prs', 250, 119),
('pr_bench_platinum', 'Bench Master', '50 bench press PRs', 'personal_records', '🏋️', 'platinum', 4, 500, 50, 'bench_prs', 500, 120)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Squat PRs
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_squat_bronze', 'Squat Progressor', '5 squat PRs', 'personal_records', '🦵', 'bronze', 1, 50, 5, 'squat_prs', 50, 121),
('pr_squat_silver', 'Squat Builder', '15 squat PRs', 'personal_records', '🦵', 'silver', 2, 100, 15, 'squat_prs', 100, 122),
('pr_squat_gold', 'Squat Beast', '30 squat PRs', 'personal_records', '🦵', 'gold', 3, 250, 30, 'squat_prs', 250, 123),
('pr_squat_platinum', 'Squat Master', '50 squat PRs', 'personal_records', '🦵', 'platinum', 4, 500, 50, 'squat_prs', 500, 124)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Deadlift PRs
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_deadlift_bronze', 'Deadlift Progressor', '5 deadlift PRs', 'personal_records', '🏋️', 'bronze', 1, 50, 5, 'deadlift_prs', 50, 125),
('pr_deadlift_silver', 'Deadlift Builder', '15 deadlift PRs', 'personal_records', '🏋️', 'silver', 2, 100, 15, 'deadlift_prs', 100, 126),
('pr_deadlift_gold', 'Deadlift Beast', '30 deadlift PRs', 'personal_records', '🏋️', 'gold', 3, 250, 30, 'deadlift_prs', 250, 127),
('pr_deadlift_platinum', 'Deadlift Master', '50 deadlift PRs', 'personal_records', '🏋️', 'platinum', 4, 500, 50, 'deadlift_prs', 500, 128)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- OHP PRs
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_ohp_bronze', 'OHP Progressor', '5 overhead press PRs', 'personal_records', '🏋️', 'bronze', 1, 50, 5, 'ohp_prs', 50, 129),
('pr_ohp_silver', 'OHP Builder', '15 overhead press PRs', 'personal_records', '🏋️', 'silver', 2, 100, 15, 'ohp_prs', 100, 130),
('pr_ohp_gold', 'OHP Beast', '30 overhead press PRs', 'personal_records', '🏋️', 'gold', 3, 250, 30, 'ohp_prs', 250, 131),
('pr_ohp_platinum', 'OHP Master', '50 overhead press PRs', 'personal_records', '🏋️', 'platinum', 4, 500, 50, 'ohp_prs', 500, 132)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Row PRs
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_row_bronze', 'Row Progressor', '5 row PRs', 'personal_records', '🏋️', 'bronze', 1, 50, 5, 'row_prs', 50, 133),
('pr_row_silver', 'Row Builder', '15 row PRs', 'personal_records', '🏋️', 'silver', 2, 100, 15, 'row_prs', 100, 134),
('pr_row_gold', 'Row Beast', '30 row PRs', 'personal_records', '🏋️', 'gold', 3, 250, 30, 'row_prs', 250, 135),
('pr_row_platinum', 'Row Master', '50 row PRs', 'personal_records', '🏋️', 'platinum', 4, 500, 50, 'row_prs', 500, 136)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Pull-up PRs
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('pr_pullup_bronze', 'Pull-up Progressor', '5 pull-up PRs', 'personal_records', '💪', 'bronze', 1, 50, 5, 'pullup_prs', 50, 137),
('pr_pullup_silver', 'Pull-up Builder', '15 pull-up PRs', 'personal_records', '💪', 'silver', 2, 100, 15, 'pullup_prs', 100, 138),
('pr_pullup_gold', 'Pull-up Beast', '30 pull-up PRs', 'personal_records', '💪', 'gold', 3, 250, 30, 'pullup_prs', 250, 139),
('pr_pullup_platinum', 'Pull-up Master', '50 pull-up PRs', 'personal_records', '💪', 'platinum', 4, 500, 50, 'pullup_prs', 500, 140)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- F. SOCIAL & COMMUNITY ACHIEVEMENTS (48 trophies)
-- ============================================

-- Posts Created
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_posts_bronze', 'First Share', 'Create 5 social posts', 'social', '📝', 'bronze', 1, 25, 5, 'posts', 25, 141),
('social_posts_silver', 'Active Poster', 'Create 50 social posts', 'social', '📝', 'silver', 2, 75, 50, 'posts', 75, 142),
('social_posts_gold', 'Content Creator', 'Create 250 social posts', 'social', '📝', 'gold', 3, 200, 250, 'posts', 200, 143),
('social_posts_platinum', 'Social Star', 'Create 1,000 social posts', 'social', '📝', 'platinum', 4, 750, 1000, 'posts', 750, 144)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Reactions Given
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_reactions_given_bronze', 'Encourager', 'Give 25 reactions', 'social', '👍', 'bronze', 1, 25, 25, 'reactions_given', 25, 145),
('social_reactions_given_silver', 'Supporter', 'Give 250 reactions', 'social', '👍', 'silver', 2, 75, 250, 'reactions_given', 75, 146),
('social_reactions_given_gold', 'Community Builder', 'Give 1,000 reactions', 'social', '👍', 'gold', 3, 200, 1000, 'reactions_given', 200, 147),
('social_reactions_given_platinum', 'Hype Machine', 'Give 10,000 reactions', 'social', '👍', 'platinum', 4, 750, 10000, 'reactions_given', 750, 148)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Reactions Received
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_reactions_received_bronze', 'Getting Noticed', 'Receive 10 reactions', 'social', '❤️', 'bronze', 1, 25, 10, 'reactions_received', 25, 149),
('social_reactions_received_silver', 'Popular', 'Receive 100 reactions', 'social', '❤️', 'silver', 2, 75, 100, 'reactions_received', 75, 150),
('social_reactions_received_gold', 'Fan Favorite', 'Receive 500 reactions', 'social', '❤️', 'gold', 3, 200, 500, 'reactions_received', 200, 151),
('social_reactions_received_platinum', 'Community Icon', 'Receive 5,000 reactions', 'social', '❤️', 'platinum', 4, 750, 5000, 'reactions_received', 750, 152)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Comments Posted
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_comments_bronze', 'Commentator', 'Post 10 comments', 'social', '💬', 'bronze', 1, 25, 10, 'comments', 25, 153),
('social_comments_silver', 'Conversationalist', 'Post 100 comments', 'social', '💬', 'silver', 2, 75, 100, 'comments', 75, 154),
('social_comments_gold', 'Discussion Leader', 'Post 500 comments', 'social', '💬', 'gold', 3, 200, 500, 'comments', 200, 155),
('social_comments_platinum', 'Voice of Community', 'Post 2,500 comments', 'social', '💬', 'platinum', 4, 750, 2500, 'comments', 750, 156)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Friends Made
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_friends_bronze', 'Making Friends', 'Connect with 3 friends', 'social', '🤝', 'bronze', 1, 25, 3, 'friends', 25, 157),
('social_friends_silver', 'Social Circle', 'Connect with 25 friends', 'social', '🤝', 'silver', 2, 75, 25, 'friends', 75, 158),
('social_friends_gold', 'Network Builder', 'Connect with 100 friends', 'social', '🤝', 'gold', 3, 200, 100, 'friends', 200, 159),
('social_friends_platinum', 'Influencer', 'Connect with 500 friends', 'social', '🤝', 'platinum', 4, 750, 500, 'friends', 750, 160)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Challenge Participation
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_challenges_joined_bronze', 'Challenge Taker', 'Join 1 challenge', 'social', '🎯', 'bronze', 1, 25, 1, 'challenges_joined', 25, 161),
('social_challenges_joined_silver', 'Challenge Regular', 'Join 25 challenges', 'social', '🎯', 'silver', 2, 100, 25, 'challenges_joined', 100, 162),
('social_challenges_joined_gold', 'Challenge Addict', 'Join 100 challenges', 'social', '🎯', 'gold', 3, 250, 100, 'challenges_joined', 250, 163),
('social_challenges_joined_platinum', 'Challenge Legend', 'Join 500 challenges', 'social', '🎯', 'platinum', 4, 1000, 500, 'challenges_joined', 1000, 164)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Challenge Wins
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_challenges_won_bronze', 'First Win', 'Win 1 challenge', 'social', '🏅', 'bronze', 1, 50, 1, 'challenges_won', 50, 165),
('social_challenges_won_silver', 'Winner', 'Win 25 challenges', 'social', '🏅', 'silver', 2, 150, 25, 'challenges_won', 150, 166),
('social_challenges_won_gold', 'Champion', 'Win 100 challenges', 'social', '🏅', 'gold', 3, 400, 100, 'challenges_won', 400, 167),
('social_challenges_won_platinum', 'Challenge King', 'Win 250 challenges', 'social', '🏅', 'platinum', 4, 1500, 250, 'challenges_won', 1500, 168)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Workout Shares
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_shares_bronze', 'Sharer', 'Share 5 workouts', 'social', '📤', 'bronze', 1, 25, 5, 'workout_shares', 25, 169),
('social_shares_silver', 'Regular Sharer', 'Share 50 workouts', 'social', '📤', 'silver', 2, 75, 50, 'workout_shares', 75, 170),
('social_shares_gold', 'Share Champion', 'Share 250 workouts', 'social', '📤', 'gold', 3, 200, 250, 'workout_shares', 200, 171),
('social_shares_platinum', 'Share Legend', 'Share 1,000 workouts', 'social', '📤', 'platinum', 4, 750, 1000, 'workout_shares', 750, 172)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Shared Workouts Completed (with friends)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_shared_workouts_bronze', 'Workout Buddy', 'Complete 1 shared workout', 'social', '👥', 'bronze', 1, 50, 1, 'shared_workouts', 50, 173),
('social_shared_workouts_silver', 'Team Player', 'Complete 25 shared workouts', 'social', '👥', 'silver', 2, 150, 25, 'shared_workouts', 150, 174),
('social_shared_workouts_gold', 'Crew Leader', 'Complete 100 shared workouts', 'social', '👥', 'gold', 3, 400, 100, 'shared_workouts', 400, 175),
('social_shared_workouts_platinum', 'Squad Legend', 'Complete 500 shared workouts', 'social', '👥', 'platinum', 4, 1500, 500, 'shared_workouts', 1500, 176)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Leaderboard Finishes (Top 10)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_leaderboard_bronze', 'Leaderboard Debut', '1 top-10 finish', 'social', '📊', 'bronze', 1, 50, 1, 'top10_finishes', 50, 177),
('social_leaderboard_silver', 'Leaderboard Regular', '10 top-10 finishes', 'social', '📊', 'silver', 2, 150, 10, 'top10_finishes', 150, 178),
('social_leaderboard_gold', 'Leaderboard Star', '50 top-10 finishes', 'social', '📊', 'gold', 3, 400, 50, 'top10_finishes', 400, 179),
('social_leaderboard_platinum', 'Leaderboard Legend', '200 top-10 finishes', 'social', '📊', 'platinum', 4, 1500, 200, 'top10_finishes', 1500, 180)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Leaderboard #1 Finishes
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_first_place_bronze', 'First Champion', '1 first place finish', 'social', '👑', 'bronze', 1, 100, 1, 'first_places', 100, 181),
('social_first_place_silver', 'Regular Champion', '10 first place finishes', 'social', '👑', 'silver', 2, 300, 10, 'first_places', 300, 182),
('social_first_place_gold', 'Top Dog', '50 first place finishes', 'social', '👑', 'gold', 3, 750, 50, 'first_places', 750, 183),
('social_first_place_platinum', 'Undefeated', '150 first place finishes', 'social', '👑', 'platinum', 4, 2500, 150, 'first_places', 2500, 184)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Community Supporter
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('social_helper_bronze', 'Helpful', '10 helpful interactions', 'social', '🙏', 'bronze', 1, 25, 10, 'helpful_interactions', 25, 185),
('social_helper_silver', 'Supportive', '100 helpful interactions', 'social', '🙏', 'silver', 2, 100, 100, 'helpful_interactions', 100, 186),
('social_helper_gold', 'Community Pillar', '500 helpful interactions', 'social', '🙏', 'gold', 3, 300, 500, 'helpful_interactions', 300, 187),
('social_helper_platinum', 'Community Hero', '2,500 helpful interactions', 'social', '🙏', 'platinum', 4, 1000, 2500, 'helpful_interactions', 1000, 188)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- G. BODY COMPOSITION & MEASUREMENTS (52 trophies)
-- ============================================

-- Weight Loss Progress
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_loss_bronze', 'Weight Loss Start', 'Lose 5 lbs from starting weight', 'body', '⚖️', 'bronze', 1, 75, 5, 'lbs_lost', 75, 189),
('body_loss_silver', 'Steady Progress', 'Lose 15 lbs from starting weight', 'body', '⚖️', 'silver', 2, 200, 15, 'lbs_lost', 200, 190),
('body_loss_gold', 'Major Transformation', 'Lose 30 lbs from starting weight', 'body', '⚖️', 'gold', 3, 500, 30, 'lbs_lost', 500, 191),
('body_loss_platinum', 'Total Makeover', 'Lose 50 lbs from starting weight', 'body', '⚖️', 'platinum', 4, 1500, 50, 'lbs_lost', 1500, 192)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Weight Gain (Bulking)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_gain_bronze', 'Bulk Start', 'Gain 5 lbs from starting weight', 'body', '💪', 'bronze', 1, 75, 5, 'lbs_gained', 75, 193),
('body_gain_silver', 'Building Mass', 'Gain 15 lbs from starting weight', 'body', '💪', 'silver', 2, 200, 15, 'lbs_gained', 200, 194),
('body_gain_gold', 'Serious Gains', 'Gain 25 lbs from starting weight', 'body', '💪', 'gold', 3, 500, 25, 'lbs_gained', 500, 195),
('body_gain_platinum', 'Mass Monster', 'Gain 40 lbs from starting weight', 'body', '💪', 'platinum', 4, 1500, 40, 'lbs_gained', 1500, 196)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Weight Logging Streak
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_weight_log_bronze', 'Weight Tracker', '7 consecutive days logged', 'body', '📊', 'bronze', 1, 25, 7, 'weight_log_streak', 25, 197),
('body_weight_log_silver', 'Consistent Logger', '30 consecutive days logged', 'body', '📊', 'silver', 2, 75, 30, 'weight_log_streak', 75, 198),
('body_weight_log_gold', 'Dedicated Tracker', '100 consecutive days logged', 'body', '📊', 'gold', 3, 200, 100, 'weight_log_streak', 200, 199),
('body_weight_log_platinum', 'Tracking Legend', '365 consecutive days logged', 'body', '📊', 'platinum', 4, 750, 365, 'weight_log_streak', 750, 200)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Total Weight Logs
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_weight_total_bronze', 'Starting to Track', '25 weight entries', 'body', '⚖️', 'bronze', 1, 25, 25, 'weight_logs', 25, 201),
('body_weight_total_silver', 'Regular Tracker', '100 weight entries', 'body', '⚖️', 'silver', 2, 75, 100, 'weight_logs', 75, 202),
('body_weight_total_gold', 'Dedicated Tracker', '365 weight entries', 'body', '⚖️', 'gold', 3, 200, 365, 'weight_logs', 200, 203),
('body_weight_total_platinum', 'Tracking Master', '1,095 weight entries', 'body', '⚖️', 'platinum', 4, 750, 1095, 'weight_logs', 750, 204)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Measurement Sessions
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_measurements_bronze', 'First Measurements', '5 measurement sessions', 'body', '📏', 'bronze', 1, 25, 5, 'measurement_sessions', 25, 205),
('body_measurements_silver', 'Regular Measurer', '25 measurement sessions', 'body', '📏', 'silver', 2, 75, 25, 'measurement_sessions', 75, 206),
('body_measurements_gold', 'Dedicated Measurer', '100 measurement sessions', 'body', '📏', 'gold', 3, 200, 100, 'measurement_sessions', 200, 207),
('body_measurements_platinum', 'Measurement Master', '365 measurement sessions', 'body', '📏', 'platinum', 4, 750, 365, 'measurement_sessions', 750, 208)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Measurement Streak (weekly)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_measure_streak_bronze', 'Monthly Measurer', '4 consecutive weeks', 'body', '📐', 'bronze', 1, 25, 4, 'measure_streak_weeks', 25, 209),
('body_measure_streak_silver', 'Quarterly Measurer', '12 consecutive weeks', 'body', '📐', 'silver', 2, 100, 12, 'measure_streak_weeks', 100, 210),
('body_measure_streak_gold', 'Yearly Measurer', '52 consecutive weeks', 'body', '📐', 'gold', 3, 350, 52, 'measure_streak_weeks', 350, 211),
('body_measure_streak_platinum', 'Measure Legend', '156 consecutive weeks', 'body', '📐', 'platinum', 4, 1250, 156, 'measure_streak_weeks', 1250, 212)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Body Parts Tracked
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_parts_bronze', 'Basic Tracking', 'Track 3 body parts', 'body', '📋', 'bronze', 1, 25, 3, 'body_parts', 25, 213),
('body_parts_silver', 'Detailed Tracking', 'Track 6 body parts', 'body', '📋', 'silver', 2, 50, 6, 'body_parts', 50, 214),
('body_parts_gold', 'Comprehensive Tracking', 'Track 10 body parts', 'body', '📋', 'gold', 3, 100, 10, 'body_parts', 100, 215),
('body_parts_platinum', 'Full Body Tracking', 'Track all 15+ body parts', 'body', '📋', 'platinum', 4, 250, 15, 'body_parts', 250, 216)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Waist Reduction
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_waist_bronze', 'Waist Reduction Start', '1 inch lost', 'body', '📏', 'bronze', 1, 50, 1, 'waist_inches_lost', 50, 217),
('body_waist_silver', 'Waist Progress', '3 inches lost', 'body', '📏', 'silver', 2, 150, 3, 'waist_inches_lost', 150, 218),
('body_waist_gold', 'Waist Transformation', '6 inches lost', 'body', '📏', 'gold', 3, 400, 6, 'waist_inches_lost', 400, 219),
('body_waist_platinum', 'Waist Master', '10+ inches lost', 'body', '📏', 'platinum', 4, 1000, 10, 'waist_inches_lost', 1000, 220)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Muscle Growth (Chest/Bicep)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('body_muscle_bronze', 'Muscle Growth Start', '0.5 inch gained', 'body', '💪', 'bronze', 1, 50, 0.5, 'muscle_inches_gained', 50, 221),
('body_muscle_silver', 'Muscle Progress', '1.5 inches gained', 'body', '💪', 'silver', 2, 150, 1.5, 'muscle_inches_gained', 150, 222),
('body_muscle_gold', 'Muscle Transformation', '3 inches gained', 'body', '💪', 'gold', 3, 400, 3, 'muscle_inches_gained', 400, 223),
('body_muscle_platinum', 'Muscle Master', '5+ inches gained', 'body', '💪', 'platinum', 4, 1000, 5, 'muscle_inches_gained', 1000, 224)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Progress Photos Taken
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('photo_count_bronze', 'Photo Start', '5 progress photos', 'body', '📸', 'bronze', 1, 25, 5, 'photos', 25, 225),
('photo_count_silver', 'Photo Regular', '25 progress photos', 'body', '📸', 'silver', 2, 75, 25, 'photos', 75, 226),
('photo_count_gold', 'Photo Dedicated', '100 progress photos', 'body', '📸', 'gold', 3, 200, 100, 'photos', 200, 227),
('photo_count_platinum', 'Photo Master', '365 progress photos', 'body', '📸', 'platinum', 4, 750, 365, 'photos', 750, 228)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Photo Streak (weekly)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('photo_streak_bronze', 'Monthly Photographer', '4 consecutive weeks', 'body', '📷', 'bronze', 1, 25, 4, 'photo_streak_weeks', 25, 229),
('photo_streak_silver', 'Quarterly Photographer', '12 consecutive weeks', 'body', '📷', 'silver', 2, 100, 12, 'photo_streak_weeks', 100, 230),
('photo_streak_gold', 'Yearly Photographer', '52 consecutive weeks', 'body', '📷', 'gold', 3, 350, 52, 'photo_streak_weeks', 350, 231),
('photo_streak_platinum', 'Photo Legend', '104 consecutive weeks', 'body', '📷', 'platinum', 4, 1000, 104, 'photo_streak_weeks', 1000, 232)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Comparison Photos
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('photo_compare_bronze', 'First Comparison', '1 side-by-side comparison', 'body', '🔄', 'bronze', 1, 25, 1, 'comparisons', 25, 233),
('photo_compare_silver', 'Comparison Regular', '10 comparisons', 'body', '🔄', 'silver', 2, 75, 10, 'comparisons', 75, 234),
('photo_compare_gold', 'Comparison Dedicated', '50 comparisons', 'body', '🔄', 'gold', 3, 200, 50, 'comparisons', 200, 235),
('photo_compare_platinum', 'Comparison Master', '200 comparisons', 'body', '🔄', 'platinum', 4, 500, 200, 'comparisons', 500, 236)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Transformation Milestones
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('transform_bronze', '1 Month Transformation', 'Document 1 month progress', 'body', '🌟', 'bronze', 1, 75, 1, 'transform_months', 75, 237),
('transform_silver', '3 Month Transformation', 'Document 3 month progress', 'body', '🌟', 'silver', 2, 200, 3, 'transform_months', 200, 238),
('transform_gold', '6 Month Transformation', 'Document 6 month progress', 'body', '🌟', 'gold', 3, 400, 6, 'transform_months', 400, 239),
('transform_platinum', '1 Year Transformation', 'Document 1 year progress', 'body', '🌟', 'platinum', 4, 1000, 12, 'transform_months', 1000, 240)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- H. NUTRITION ACHIEVEMENTS (32 trophies)
-- ============================================

-- Meals Logged
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_meals_bronze', 'Meal Logger', 'Log 25 meals', 'nutrition', '🍽️', 'bronze', 1, 25, 25, 'meals', 25, 241),
('nutrition_meals_silver', 'Regular Logger', 'Log 250 meals', 'nutrition', '🍽️', 'silver', 2, 75, 250, 'meals', 75, 242),
('nutrition_meals_gold', 'Dedicated Logger', 'Log 1,000 meals', 'nutrition', '🍽️', 'gold', 3, 200, 1000, 'meals', 200, 243),
('nutrition_meals_platinum', 'Logging Legend', 'Log 5,000 meals', 'nutrition', '🍽️', 'platinum', 4, 750, 5000, 'meals', 750, 244)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Calorie Tracking Days
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_calories_bronze', 'Calorie Starter', '7 days tracked', 'nutrition', '🔢', 'bronze', 1, 25, 7, 'calorie_days', 25, 245),
('nutrition_calories_silver', 'Calorie Regular', '30 days tracked', 'nutrition', '🔢', 'silver', 2, 75, 30, 'calorie_days', 75, 246),
('nutrition_calories_gold', 'Calorie Dedicated', '180 days tracked', 'nutrition', '🔢', 'gold', 3, 250, 180, 'calorie_days', 250, 247),
('nutrition_calories_platinum', 'Calorie Master', '730 days tracked', 'nutrition', '🔢', 'platinum', 4, 1000, 730, 'calorie_days', 1000, 248)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Protein Goals Hit
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_protein_bronze', 'Protein Starter', '10 days at goal', 'nutrition', '🥩', 'bronze', 1, 25, 10, 'protein_goal_days', 25, 249),
('nutrition_protein_silver', 'Protein Regular', '50 days at goal', 'nutrition', '🥩', 'silver', 2, 100, 50, 'protein_goal_days', 100, 250),
('nutrition_protein_gold', 'Protein Dedicated', '200 days at goal', 'nutrition', '🥩', 'gold', 3, 300, 200, 'protein_goal_days', 300, 251),
('nutrition_protein_platinum', 'Protein Master', '730 days at goal', 'nutrition', '🥩', 'platinum', 4, 1250, 730, 'protein_goal_days', 1250, 252)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Meal Prep Days
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_prep_bronze', 'Meal Prepper', '5 prep sessions', 'nutrition', '🥗', 'bronze', 1, 25, 5, 'prep_sessions', 25, 253),
('nutrition_prep_silver', 'Regular Prepper', '50 prep sessions', 'nutrition', '🥗', 'silver', 2, 100, 50, 'prep_sessions', 100, 254),
('nutrition_prep_gold', 'Dedicated Prepper', '200 prep sessions', 'nutrition', '🥗', 'gold', 3, 300, 200, 'prep_sessions', 300, 255),
('nutrition_prep_platinum', 'Prep Master', '520 prep sessions', 'nutrition', '🥗', 'platinum', 4, 1000, 520, 'prep_sessions', 1000, 256)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Water Intake Goals
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_water_bronze', 'Hydration Starter', '7 days at goal', 'nutrition', '💧', 'bronze', 1, 25, 7, 'water_goal_days', 25, 257),
('nutrition_water_silver', 'Hydration Regular', '30 days at goal', 'nutrition', '💧', 'silver', 2, 75, 30, 'water_goal_days', 75, 258),
('nutrition_water_gold', 'Hydration Dedicated', '180 days at goal', 'nutrition', '💧', 'gold', 3, 250, 180, 'water_goal_days', 250, 259),
('nutrition_water_platinum', 'Hydration Master', '730 days at goal', 'nutrition', '💧', 'platinum', 4, 1000, 730, 'water_goal_days', 1000, 260)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Clean Eating Streaks
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_clean_bronze', 'Clean Starter', '3 days clean eating', 'nutrition', '🥬', 'bronze', 1, 25, 3, 'clean_days', 25, 261),
('nutrition_clean_silver', 'Clean Regular', '14 days clean eating', 'nutrition', '🥬', 'silver', 2, 100, 14, 'clean_days', 100, 262),
('nutrition_clean_gold', 'Clean Dedicated', '30 days clean eating', 'nutrition', '🥬', 'gold', 3, 300, 30, 'clean_days', 300, 263),
('nutrition_clean_platinum', 'Clean Master', '100 days clean eating', 'nutrition', '🥬', 'platinum', 4, 1000, 100, 'clean_days', 1000, 264)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Macro Balance Days
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_macro_bronze', 'Macro Starter', '7 balanced days', 'nutrition', '⚖️', 'bronze', 1, 25, 7, 'macro_days', 25, 265),
('nutrition_macro_silver', 'Macro Regular', '30 balanced days', 'nutrition', '⚖️', 'silver', 2, 100, 30, 'macro_days', 100, 266),
('nutrition_macro_gold', 'Macro Dedicated', '100 balanced days', 'nutrition', '⚖️', 'gold', 3, 300, 100, 'macro_days', 300, 267),
('nutrition_macro_platinum', 'Macro Master', '365 balanced days', 'nutrition', '⚖️', 'platinum', 4, 1250, 365, 'macro_days', 1250, 268)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Supplement Tracking
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('nutrition_supps_bronze', 'Supplement Starter', 'Track 10 times', 'nutrition', '💊', 'bronze', 1, 15, 10, 'supp_logs', 15, 269),
('nutrition_supps_silver', 'Supplement Regular', 'Track 100 times', 'nutrition', '💊', 'silver', 2, 50, 100, 'supp_logs', 50, 270),
('nutrition_supps_gold', 'Supplement Dedicated', 'Track 500 times', 'nutrition', '💊', 'gold', 3, 150, 500, 'supp_logs', 150, 271),
('nutrition_supps_platinum', 'Supplement Master', 'Track 2,000 times', 'nutrition', '💊', 'platinum', 4, 500, 2000, 'supp_logs', 500, 272)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- I. FASTING ACHIEVEMENTS (20 trophies)
-- ============================================

-- Intermittent Fasts (16:8)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('fasting_if_bronze', 'IF Starter', '5 intermittent fasts', 'fasting', '⏰', 'bronze', 1, 25, 5, 'if_fasts', 25, 273),
('fasting_if_silver', 'IF Regular', '50 intermittent fasts', 'fasting', '⏰', 'silver', 2, 100, 50, 'if_fasts', 100, 274),
('fasting_if_gold', 'IF Dedicated', '200 intermittent fasts', 'fasting', '⏰', 'gold', 3, 300, 200, 'if_fasts', 300, 275),
('fasting_if_platinum', 'IF Legend', '730 intermittent fasts', 'fasting', '⏰', 'platinum', 4, 1250, 730, 'if_fasts', 1250, 276)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Extended Fasts (24+ hours)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('fasting_extended_bronze', 'Extended Starter', '1 extended fast', 'fasting', '🕐', 'bronze', 1, 50, 1, 'extended_fasts', 50, 277),
('fasting_extended_silver', 'Extended Regular', '10 extended fasts', 'fasting', '🕐', 'silver', 2, 150, 10, 'extended_fasts', 150, 278),
('fasting_extended_gold', 'Extended Dedicated', '50 extended fasts', 'fasting', '🕐', 'gold', 3, 400, 50, 'extended_fasts', 400, 279),
('fasting_extended_platinum', 'Extended Master', '150 extended fasts', 'fasting', '🕐', 'platinum', 4, 1500, 150, 'extended_fasts', 1500, 280)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Longest Fast Duration
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('fasting_duration_bronze', '16 Hour Fast', 'Complete 16-hour fast', 'fasting', '⏱️', 'bronze', 1, 25, 16, 'hours', 25, 281),
('fasting_duration_silver', '24 Hour Fast', 'Complete 24-hour fast', 'fasting', '⏱️', 'silver', 2, 100, 24, 'hours', 100, 282),
('fasting_duration_gold', '48 Hour Fast', 'Complete 48-hour fast', 'fasting', '⏱️', 'gold', 3, 300, 48, 'hours', 300, 283),
('fasting_duration_platinum', '72+ Hour Fast', 'Complete 72+ hour fast', 'fasting', '⏱️', 'platinum', 4, 750, 72, 'hours', 750, 284)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Fasting Streak
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('fasting_streak_bronze', 'Fasting Week', '7 consecutive fasting days', 'fasting', '🔥', 'bronze', 1, 50, 7, 'fasting_streak', 50, 285),
('fasting_streak_silver', 'Fasting Month', '30 consecutive fasting days', 'fasting', '🔥', 'silver', 2, 200, 30, 'fasting_streak', 200, 286),
('fasting_streak_gold', 'Fasting Century', '100 consecutive fasting days', 'fasting', '🔥', 'gold', 3, 500, 100, 'fasting_streak', 500, 287),
('fasting_streak_platinum', 'Fasting Year', '365 consecutive fasting days', 'fasting', '🔥', 'platinum', 4, 2000, 365, 'fasting_streak', 2000, 288)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Total Fasting Hours
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('fasting_hours_bronze', '100 Fasting Hours', '100 total fasting hours', 'fasting', '⌛', 'bronze', 1, 50, 100, 'total_fasting_hours', 50, 289),
('fasting_hours_silver', '500 Fasting Hours', '500 total fasting hours', 'fasting', '⌛', 'silver', 2, 150, 500, 'total_fasting_hours', 150, 290),
('fasting_hours_gold', '2000 Fasting Hours', '2,000 total fasting hours', 'fasting', '⌛', 'gold', 3, 400, 2000, 'total_fasting_hours', 400, 291),
('fasting_hours_platinum', '10000 Fasting Hours', '10,000 total fasting hours', 'fasting', '⌛', 'platinum', 4, 1500, 10000, 'total_fasting_hours', 1500, 292)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- J. AI COACH ENGAGEMENT (28 trophies)
-- ============================================

-- Chat Messages Sent
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('coach_messages_bronze', 'Chat Starter', '25 messages sent', 'coach', '💬', 'bronze', 1, 15, 25, 'messages', 15, 293),
('coach_messages_silver', 'Chat Regular', '250 messages sent', 'coach', '💬', 'silver', 2, 50, 250, 'messages', 50, 294),
('coach_messages_gold', 'Chat Enthusiast', '1,000 messages sent', 'coach', '💬', 'gold', 3, 150, 1000, 'messages', 150, 295),
('coach_messages_platinum', 'Chat Legend', '5,000 messages sent', 'coach', '💬', 'platinum', 4, 500, 5000, 'messages', 500, 296)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Coach Sessions
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('coach_sessions_bronze', 'Session Starter', '10 coach sessions', 'coach', '🤖', 'bronze', 1, 25, 10, 'sessions', 25, 297),
('coach_sessions_silver', 'Session Regular', '100 coach sessions', 'coach', '🤖', 'silver', 2, 75, 100, 'sessions', 75, 298),
('coach_sessions_gold', 'Session Dedicated', '500 coach sessions', 'coach', '🤖', 'gold', 3, 200, 500, 'sessions', 200, 299),
('coach_sessions_platinum', 'Session Legend', '2,000 coach sessions', 'coach', '🤖', 'platinum', 4, 750, 2000, 'sessions', 750, 300)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Questions Asked
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('coach_questions_bronze', 'Curious Beginner', '10 questions asked', 'coach', '❓', 'bronze', 1, 15, 10, 'questions', 15, 301),
('coach_questions_silver', 'Knowledge Seeker', '100 questions asked', 'coach', '❓', 'silver', 2, 50, 100, 'questions', 50, 302),
('coach_questions_gold', 'Learning Enthusiast', '500 questions asked', 'coach', '❓', 'gold', 3, 150, 500, 'questions', 150, 303),
('coach_questions_platinum', 'Wisdom Hunter', '2,500 questions asked', 'coach', '❓', 'platinum', 4, 500, 2500, 'questions', 500, 304)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Advice Followed
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('coach_advice_bronze', 'Advice Taker', '5 coach suggestions followed', 'coach', '✅', 'bronze', 1, 25, 5, 'advice_followed', 25, 305),
('coach_advice_silver', 'Good Student', '50 coach suggestions followed', 'coach', '✅', 'silver', 2, 100, 50, 'advice_followed', 100, 306),
('coach_advice_gold', 'Star Pupil', '250 coach suggestions followed', 'coach', '✅', 'gold', 3, 300, 250, 'advice_followed', 300, 307),
('coach_advice_platinum', 'Perfect Student', '1,000 coach suggestions followed', 'coach', '✅', 'platinum', 4, 1000, 1000, 'advice_followed', 1000, 308)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Workout Modifications
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('coach_mods_bronze', 'Modifier Starter', '5 workout modifications', 'coach', '🔄', 'bronze', 1, 15, 5, 'modifications', 15, 309),
('coach_mods_silver', 'Modifier Regular', '50 workout modifications', 'coach', '🔄', 'silver', 2, 50, 50, 'modifications', 50, 310),
('coach_mods_gold', 'Modifier Expert', '200 workout modifications', 'coach', '🔄', 'gold', 3, 150, 200, 'modifications', 150, 311),
('coach_mods_platinum', 'Modifier Master', '1,000 workout modifications', 'coach', '🔄', 'platinum', 4, 500, 1000, 'modifications', 500, 312)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Form Check Requests
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('coach_form_bronze', 'Form Checker', '5 form check requests', 'coach', '📐', 'bronze', 1, 25, 5, 'form_checks', 25, 313),
('coach_form_silver', 'Form Conscious', '50 form check requests', 'coach', '📐', 'silver', 2, 75, 50, 'form_checks', 75, 314),
('coach_form_gold', 'Form Perfectionist', '200 form check requests', 'coach', '📐', 'gold', 3, 200, 200, 'form_checks', 200, 315),
('coach_form_platinum', 'Form Master', '1,000 form check requests', 'coach', '📐', 'platinum', 4, 750, 1000, 'form_checks', 750, 316)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- Personalization Feedback
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order) VALUES
('coach_feedback_bronze', 'Feedback Starter', '10 feedback items given', 'coach', '📝', 'bronze', 1, 15, 10, 'feedback', 15, 317),
('coach_feedback_silver', 'Feedback Regular', '50 feedback items given', 'coach', '📝', 'silver', 2, 50, 50, 'feedback', 50, 318),
('coach_feedback_gold', 'Feedback Enthusiast', '200 feedback items given', 'coach', '📝', 'gold', 3, 150, 200, 'feedback', 150, 319),
('coach_feedback_platinum', 'Feedback Champion', '1,000 feedback items given', 'coach', '📝', 'platinum', 4, 500, 1000, 'feedback', 500, 320)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order;

-- ============================================
-- K. SECRET/SPECIAL ACHIEVEMENTS (40 trophies)
-- ============================================

-- Time-Based Secret
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_secret, hint_text) VALUES
('secret_dawn', 'Dawn Warrior', 'Workout at sunrise (5-6 AM)', 'secret', '🌅', 'silver', 2, 75, NULL, NULL, 75, 321, true, 'The early bird catches the gains...'),
('secret_midnight', 'Midnight Grinder', 'Workout after midnight', 'secret', '🌙', 'silver', 2, 75, NULL, NULL, 75, 322, true, 'When the clock strikes twelve...'),
('secret_newyear', 'New Year Crusher', 'Workout on January 1st', 'secret', '🎆', 'gold', 3, 150, NULL, NULL, 150, 323, true, 'Start the year right...'),
('secret_halloween', 'Halloween Hustle', 'Workout on October 31st', 'secret', '🎃', 'gold', 3, 150, NULL, NULL, 150, 324, true, 'No rest for the wicked...'),
('secret_birthday', 'Birthday Gains', 'Workout on your birthday', 'secret', '🎂', 'gold', 3, 200, NULL, NULL, 200, 325, true, 'Celebrate with sweat...'),
('secret_thanksgiving', 'Turkey Burner', 'Workout on Thanksgiving', 'secret', '🦃', 'gold', 3, 150, NULL, NULL, 150, 326, true, 'Work off the feast...'),
('secret_christmas', 'Christmas Crusher', 'Workout on December 25th', 'secret', '🎄', 'gold', 3, 150, NULL, NULL, 150, 327, true, 'Santa lifts heavy...'),
('secret_valentine', 'Valentine Gains', 'Workout on February 14th', 'secret', '❤️', 'gold', 3, 150, NULL, NULL, 150, 328, true, 'Love yourself first...')
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order, is_secret = EXCLUDED.is_secret, hint_text = EXCLUDED.hint_text;

-- Challenge-Based Secret
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_secret, hint_text) VALUES
('secret_fire_starter', 'Fire Starter', '5 workouts in first week', 'secret', '🔥', 'silver', 2, 100, 5, 'first_week_workouts', 100, 329, true, 'Hit the ground running...'),
('secret_diamond_hands', 'Diamond Hands', 'No skips for 30 days', 'secret', '💎', 'gold', 3, 300, 30, 'no_skip_days', 300, 330, true, 'Never let go...'),
('secret_iron_will', 'Iron Will', 'Complete workout despite low energy', 'secret', '🦾', 'silver', 2, 100, NULL, NULL, 100, 331, true, 'Push through the pain...'),
('secret_summit', 'Summit Seeker', 'Complete hardest difficulty workout', 'secret', '🏔️', 'gold', 3, 200, NULL, NULL, 200, 332, true, 'Reach the top...'),
('secret_tornado', 'Tornado', '3 workouts in one day', 'secret', '🌪️', 'gold', 3, 250, 3, 'daily_workouts', 250, 333, true, 'A whirlwind of activity...'),
('secret_sniper', 'Sniper', 'Hit exact target weight on all sets', 'secret', '🎯', 'silver', 2, 100, NULL, NULL, 100, 334, true, 'Precision matters...'),
('secret_launch', 'Launch Pad', '10 workouts in first month', 'secret', '🚀', 'bronze', 1, 75, 10, 'first_month_workouts', 75, 335, true, 'Blast off strong...'),
('secret_century', 'Century Year', '100 workouts in a calendar year', 'secret', '💯', 'gold', 3, 400, 100, 'yearly_workouts', 400, 336, true, 'Triple digits...')
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order, is_secret = EXCLUDED.is_secret, hint_text = EXCLUDED.hint_text;

-- Social Secret
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_secret, hint_text) VALUES
('secret_butterfly', 'Social Butterfly', 'React to 100 posts in one week', 'secret', '🦋', 'silver', 2, 100, 100, 'weekly_reactions', 100, 337, true, 'Spread those wings...'),
('secret_influencer', 'Influencer', '1000 reactions on a single post', 'secret', '📣', 'platinum', 4, 500, 1000, 'single_post_reactions', 500, 338, true, 'Go viral...'),
('secret_party_host', 'Party Host', 'Create challenge with 50+ participants', 'secret', '🎪', 'gold', 3, 300, 50, 'challenge_participants', 300, 339, true, 'Build a crowd...'),
('secret_squad', 'Squad Goals', 'Workout with 5+ friends simultaneously', 'secret', '👥', 'gold', 3, 250, 5, 'simultaneous_friends', 250, 340, true, 'Strength in numbers...'),
('secret_talk', 'Conversationalist', '50+ comments in one week', 'secret', '💬', 'silver', 2, 100, 50, 'weekly_comments', 100, 341, true, 'Join the conversation...'),
('secret_rising', 'Rising Star', 'First to complete a new challenge', 'secret', '🌟', 'gold', 3, 200, NULL, NULL, 200, 342, true, 'Be the pioneer...')
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order, is_secret = EXCLUDED.is_secret, hint_text = EXCLUDED.hint_text;

-- Nutrition/Fasting Secret
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_secret, hint_text) VALUES
('secret_clean', 'Clean Machine', '30-day streak with no cheat meals', 'secret', '🥗', 'gold', 3, 300, 30, 'clean_streak', 300, 343, true, 'Pure discipline...'),
('secret_meal_master', 'Meal Master', 'Perfect macros for 7 consecutive days', 'secret', '🍳', 'gold', 3, 250, 7, 'perfect_macro_days', 250, 344, true, 'Balance is key...'),
('secret_fast_champ', 'Fasting Champion', 'Complete 72-hour fast', 'secret', '⏱️', 'platinum', 4, 500, 72, 'fasting_hours', 500, 345, true, 'The ultimate test...'),
('secret_hydration', 'Hydration Hero', 'Hit water goal for 100 consecutive days', 'secret', '💧', 'gold', 3, 300, 100, 'water_streak', 300, 346, true, 'Stay hydrated...')
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order, is_secret = EXCLUDED.is_secret, hint_text = EXCLUDED.hint_text;

-- AI Coach Secret
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_secret, hint_text) VALUES
('secret_best_friends', 'Best Friends', '500+ messages with AI coach', 'secret', '🤖', 'gold', 3, 250, 500, 'coach_messages', 250, 347, true, 'Your AI BFF...'),
('secret_knowledge', 'Knowledge Seeker', '100 unique questions asked', 'secret', '🧠', 'gold', 3, 200, 100, 'unique_questions', 200, 348, true, 'Always learning...'),
('secret_feedback_champ', 'Feedback Champion', '50 workout feedback ratings', 'secret', '📝', 'silver', 2, 100, 50, 'workout_ratings', 100, 349, true, 'Your opinion matters...'),
('secret_student', 'Student of the Game', 'Follow coach advice 100 times', 'secret', '🎓', 'gold', 3, 250, 100, 'advice_followed', 250, 350, true, 'Listen and learn...')
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order, is_secret = EXCLUDED.is_secret, hint_text = EXCLUDED.hint_text;

-- Hidden Achievements (completely invisible until earned)
INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, points, threshold_value, threshold_unit, xp_reward, sort_order, is_hidden) VALUES
('hidden_easter', 'Easter Egg', 'Find the hidden feature', 'hidden', '🥚', 'gold', 3, 200, NULL, NULL, 200, 351, true),
('hidden_perfectionist', 'Perfectionist', '100% completion rate for 3 months', 'hidden', '🎯', 'platinum', 4, 500, 90, 'perfect_days', 500, 352, true),
('hidden_overachiever', 'Overachiever', 'Exceed weekly goal by 300%', 'hidden', '🏆', 'gold', 3, 300, 300, 'weekly_percent', 300, 353, true),
('hidden_king', 'King of Consistency', '2000 total workouts', 'hidden', '👑', 'platinum', 4, 2000, 2000, 'workouts', 2000, 354, true),
('hidden_night_legend', 'Night Owl Legend', '100 workouts after 10 PM', 'hidden', '🌌', 'gold', 3, 250, 100, 'night_workouts', 250, 355, true),
('hidden_iron_legend', 'Iron Legend', 'Lift 5 million lbs lifetime', 'hidden', '🏋️', 'platinum', 4, 2000, 5000000, 'lbs_lifted', 2000, 356, true),
('hidden_app_addict', 'App Addict', '365 consecutive days of app opens', 'hidden', '📱', 'platinum', 4, 1000, 365, 'app_open_streak', 1000, 357, true),
('hidden_oracle', 'Oracle', 'Perfect workout prediction', 'hidden', '🔮', 'silver', 2, 150, NULL, NULL, 150, 358, true),
('hidden_comeback', 'The Comeback', 'Return after 30+ day break with 7-day streak', 'hidden', '🔙', 'gold', 3, 250, NULL, NULL, 250, 359, true),
('hidden_clutch', 'Clutch Player', 'Complete workout in final hour of day', 'hidden', '⏰', 'silver', 2, 100, NULL, NULL, 100, 360, true)
ON CONFLICT (id) DO UPDATE SET tier_level = EXCLUDED.tier_level, xp_reward = EXCLUDED.xp_reward, sort_order = EXCLUDED.sort_order, is_hidden = EXCLUDED.is_hidden;

-- ============================================
-- Create indexes for new columns
-- ============================================
CREATE INDEX IF NOT EXISTS idx_achievement_types_tier_level ON achievement_types(tier_level);
CREATE INDEX IF NOT EXISTS idx_achievement_types_category ON achievement_types(category);
CREATE INDEX IF NOT EXISTS idx_achievement_types_is_secret ON achievement_types(is_secret);
CREATE INDEX IF NOT EXISTS idx_achievement_types_is_hidden ON achievement_types(is_hidden);
CREATE INDEX IF NOT EXISTS idx_achievement_types_sort_order ON achievement_types(sort_order);

-- ============================================
-- Update user_achievements with XP tracking
-- ============================================
ALTER TABLE user_achievements
ADD COLUMN IF NOT EXISTS xp_awarded INT DEFAULT 0;

-- ============================================
-- Function: Get achievement progress for user
-- ============================================
CREATE OR REPLACE FUNCTION get_achievement_progress(p_user_id UUID)
RETURNS TABLE(
    achievement_id VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    category VARCHAR(50),
    icon VARCHAR(10),
    tier VARCHAR(20),
    tier_level INT,
    threshold_value FLOAT,
    threshold_unit VARCHAR(20),
    xp_reward INT,
    is_secret BOOLEAN,
    is_hidden BOOLEAN,
    hint_text TEXT,
    is_earned BOOLEAN,
    earned_at TIMESTAMPTZ,
    current_progress FLOAT,
    progress_percent DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        at.id,
        at.name,
        at.description,
        at.category,
        at.icon,
        at.tier,
        at.tier_level,
        at.threshold_value,
        at.threshold_unit,
        at.xp_reward,
        at.is_secret,
        at.is_hidden,
        at.hint_text,
        (ua.id IS NOT NULL) as is_earned,
        ua.earned_at,
        COALESCE(ua.trigger_value, 0) as current_progress,
        CASE
            WHEN ua.id IS NOT NULL THEN 100.0
            WHEN at.threshold_value IS NULL OR at.threshold_value = 0 THEN 0.0
            ELSE LEAST(100.0, ROUND((COALESCE(ua.trigger_value, 0) / at.threshold_value) * 100, 1))
        END as progress_percent
    FROM achievement_types at
    LEFT JOIN user_achievements ua ON at.id = ua.achievement_id AND ua.user_id = p_user_id
    WHERE
        -- Show all non-hidden achievements
        at.is_hidden = FALSE
        -- Or show hidden achievements if earned
        OR ua.id IS NOT NULL
    ORDER BY at.sort_order, at.tier_level;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_achievement_progress IS 'Returns all achievements with progress for a user, hiding secret/hidden achievements appropriately';
