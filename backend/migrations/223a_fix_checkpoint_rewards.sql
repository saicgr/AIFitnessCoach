-- Migration 223a: Fix checkpoint_rewards table structure
-- Adds missing columns for the XP system migrations

-- =====================================================
-- 1. ADD MISSING COLUMNS TO checkpoint_rewards
-- =====================================================

-- Add period_type column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'checkpoint_rewards' AND column_name = 'period_type'
  ) THEN
    ALTER TABLE checkpoint_rewards ADD COLUMN period_type TEXT DEFAULT 'daily';
  END IF;
END $$;

-- Add description column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'checkpoint_rewards' AND column_name = 'description'
  ) THEN
    ALTER TABLE checkpoint_rewards ADD COLUMN description TEXT;
  END IF;
END $$;

-- =====================================================
-- 2. CREATE level_rewards TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS level_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level INTEGER NOT NULL,
  reward_type TEXT NOT NULL, -- 'badge', 'crate', 'xp_bonus', 'physical'
  reward_value TEXT NOT NULL, -- badge_id, crate_type, bonus_percent, or physical item
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(level, reward_type, reward_value)
);

CREATE INDEX IF NOT EXISTS idx_level_rewards_level ON level_rewards(level);

-- =====================================================
-- 3. ALLOW NULL FOR metric_name
-- =====================================================

ALTER TABLE checkpoint_rewards ALTER COLUMN metric_name DROP NOT NULL;

-- =====================================================
-- 4. INSERT MONTHLY ACHIEVEMENT REWARDS
-- =====================================================

INSERT INTO checkpoint_rewards (checkpoint_type, metric_name, period_type, xp_reward, description)
VALUES
  ('monthly_dedication', 'active_days', 'monthly', 500, '20+ active days this month'),
  ('monthly_goal', 'goal_progress', 'monthly', 1000, 'Hit your primary fitness goal'),
  ('monthly_nutrition', 'nutrition_days', 'monthly', 500, 'Hit macros 20+ days'),
  ('monthly_consistency', 'missed_workouts', 'monthly', 750, 'No missed scheduled workouts'),
  ('monthly_hydration', 'hydration_days', 'monthly', 300, 'Hit water goal 25+ days'),
  ('monthly_weight', 'weight_on_track', 'monthly', 400, 'On track with weight goal'),
  ('monthly_habits', 'habit_completion', 'monthly', 400, '80%+ habit completion'),
  ('monthly_prs', 'personal_records', 'monthly', 500, 'Set 3+ personal records'),
  ('monthly_social_star', 'posts_shared', 'monthly', 300, 'Share 10+ posts'),
  ('monthly_supporter', 'social_interactions', 'monthly', 200, 'React/comment on 50+ posts'),
  ('monthly_networker', 'friends_added', 'monthly', 250, 'Add 10+ friends'),
  ('monthly_measurements', 'measurement_logs', 'monthly', 150, 'Log measurements 8+ times')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 5. INSERT SOCIAL XP REWARDS
-- =====================================================

INSERT INTO checkpoint_rewards (checkpoint_type, metric_name, period_type, xp_reward, description)
VALUES
  ('social_share', 'shares_count', 'daily', 15, 'Share a post (max 3/day)'),
  ('social_react', 'reactions_count', 'daily', 5, 'React to a post (max 10/day)'),
  ('social_comment', 'comments_count', 'daily', 10, 'Comment on a post (max 5/day)'),
  ('social_friend', 'friends_count', 'daily', 25, 'Add a friend (max 5/day)')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 6. INSERT LEVEL MILESTONE REWARDS
-- =====================================================

INSERT INTO level_rewards (level, reward_type, reward_value, description)
VALUES
  -- Novice tier rewards (1-10)
  (5, 'crate', 'fitness_crate_1', 'Fitness Crate'),
  (10, 'badge', 'novice_complete', 'Novice Complete Badge'),
  (10, 'crate', 'fitness_crate_2', '2x Fitness Crates'),

  -- Apprentice tier rewards (11-25)
  (15, 'crate', 'fitness_crate_2', '2x Fitness Crates'),
  (20, 'xp_bonus', '5', '+5% XP Bonus'),
  (25, 'badge', 'apprentice_complete', 'Apprentice Complete Badge'),
  (25, 'crate', 'premium_crate_1', 'Premium Crate'),

  -- Athlete tier rewards (26-50)
  (30, 'crate', 'fitness_crate_3', '3x Fitness Crates'),
  (40, 'xp_bonus', '8', '+8% XP Bonus'),
  (50, 'badge', 'athlete_complete', 'Athlete Complete Badge'),
  (50, 'crate', 'premium_crate_2', '2x Premium Crates'),

  -- Elite tier rewards (51-75)
  (60, 'crate', 'premium_crate_2', '2x Premium Crates'),
  (70, 'xp_bonus', '10', '+10% XP Bonus'),
  (75, 'badge', 'elite_complete', 'Elite Complete Badge'),
  (75, 'crate', 'premium_crate_3', '3x Premium Crates'),

  -- Master tier rewards (76-99)
  (80, 'crate', 'premium_crate_3', '3x Premium Crates'),
  (90, 'xp_bonus', '12', '+12% XP Bonus'),

  -- Legend milestone (100)
  (100, 'badge', 'legend_badge', 'Legend Badge'),
  (100, 'crate', 'mythic_crate_1', 'Mythic Crate'),
  (100, 'physical', 'fitwiz_tshirt', 'FitWiz Legend T-Shirt'),

  -- Mythic I milestones (101-150)
  (110, 'badge', 'mythic_badge_1', 'Mythic Badge I'),
  (110, 'crate', 'mythic_crate_2', '2x Mythic Crates'),
  (125, 'crate', 'mythic_crate_1', 'Mythic Crate'),
  (125, 'xp_bonus', '15', '+15% XP Bonus'),
  (140, 'crate', 'mythic_crate_3', '3x Mythic Crates'),
  (150, 'badge', 'mythic_champion_1', 'Mythic Champion I Badge'),
  (150, 'crate', 'mythic_crate_5', '5x Mythic Crates'),
  (150, 'physical', 'custom_medal', 'Custom FitWiz Medal'),

  -- Mythic II milestones (151-200)
  (160, 'crate', 'mythic_crate_3', '3x Mythic Crates'),
  (175, 'badge', 'mythic_badge_2', 'Mythic Badge II'),
  (175, 'crate', 'mythic_crate_5', '5x Mythic Crates'),
  (190, 'xp_bonus', '20', '+20% XP Bonus'),
  (200, 'badge', 'mythic_champion_2', 'Mythic Champion II Badge'),
  (200, 'crate', 'legendary_crate_1', 'Legendary Crate'),
  (200, 'physical', 'premium_hoodie', 'Premium FitWiz Hoodie'),

  -- Mythic III milestones (201-250)
  (210, 'crate', 'legendary_crate_2', '2x Legendary Crates'),
  (225, 'badge', 'mythic_badge_3', 'Mythic Badge III'),
  (225, 'crate', 'legendary_crate_3', '3x Legendary Crates'),
  (240, 'xp_bonus', '25', '+25% XP Bonus'),
  (250, 'badge', 'eternal_legend', 'Eternal Legend Badge'),
  (250, 'crate', 'legendary_crate_10', '10x Legendary Crates'),
  (250, 'physical', 'lifetime_membership', 'Lifetime FitWiz Premium'),
  (250, 'physical', 'ultimate_merch_kit', 'Ultimate Merch Kit')
ON CONFLICT DO NOTHING;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
