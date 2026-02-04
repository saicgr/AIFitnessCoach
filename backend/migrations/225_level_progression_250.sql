-- Migration 225: Extended Level Progression to 250
-- Updates the level progression system to support levels 101-250 (Mythic tiers)

-- =====================================================
-- 1. UPDATE calculate_level_from_xp FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_level_from_xp(p_total_xp INTEGER)
RETURNS TABLE (
  current_level INTEGER,
  xp_in_current_level INTEGER,
  xp_to_next_level INTEGER,
  title TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_remaining_xp INTEGER;
  v_level INTEGER := 1;
  v_level_xp INTEGER;
  v_xp_in_level INTEGER;
  v_title TEXT;
BEGIN
  v_remaining_xp := p_total_xp;

  -- Calculate level based on XP thresholds
  -- Levels 1-10 (Novice): 50 XP each = 500 XP total
  -- Levels 11-25 (Apprentice): 100 XP each = 1,500 XP total
  -- Levels 26-50 (Athlete): 150 XP each = 3,750 XP total
  -- Levels 51-75 (Elite): 200 XP each = 5,000 XP total
  -- Levels 76-99 (Master): 250 XP each = 6,000 XP total
  -- Level 100 (Legend): 300 XP = 300 XP total
  -- Levels 101-150 (Mythic I): 350 XP each = 17,500 XP total
  -- Levels 151-200 (Mythic II): 400 XP each = 20,000 XP total
  -- Levels 201-250 (Mythic III): 500 XP each = 25,000 XP total

  WHILE v_remaining_xp > 0 AND v_level < 250 LOOP
    -- Determine XP needed for current level
    IF v_level <= 10 THEN
      v_level_xp := 50;
    ELSIF v_level <= 25 THEN
      v_level_xp := 100;
    ELSIF v_level <= 50 THEN
      v_level_xp := 150;
    ELSIF v_level <= 75 THEN
      v_level_xp := 200;
    ELSIF v_level <= 99 THEN
      v_level_xp := 250;
    ELSIF v_level = 100 THEN
      v_level_xp := 300;
    ELSIF v_level <= 150 THEN
      v_level_xp := 350;
    ELSIF v_level <= 200 THEN
      v_level_xp := 400;
    ELSE
      v_level_xp := 500;
    END IF;

    IF v_remaining_xp >= v_level_xp THEN
      v_remaining_xp := v_remaining_xp - v_level_xp;
      v_level := v_level + 1;
    ELSE
      EXIT;
    END IF;
  END LOOP;

  -- Calculate XP in current level and XP needed for next level
  v_xp_in_level := v_remaining_xp;

  IF v_level <= 10 THEN
    v_level_xp := 50;
  ELSIF v_level <= 25 THEN
    v_level_xp := 100;
  ELSIF v_level <= 50 THEN
    v_level_xp := 150;
  ELSIF v_level <= 75 THEN
    v_level_xp := 200;
  ELSIF v_level <= 99 THEN
    v_level_xp := 250;
  ELSIF v_level = 100 THEN
    v_level_xp := 300;
  ELSIF v_level <= 150 THEN
    v_level_xp := 350;
  ELSIF v_level <= 200 THEN
    v_level_xp := 400;
  ELSE
    v_level_xp := 500;
  END IF;

  -- Determine title based on level
  IF v_level <= 10 THEN
    v_title := 'Novice';
  ELSIF v_level <= 25 THEN
    v_title := 'Apprentice';
  ELSIF v_level <= 50 THEN
    v_title := 'Athlete';
  ELSIF v_level <= 75 THEN
    v_title := 'Elite';
  ELSIF v_level <= 99 THEN
    v_title := 'Master';
  ELSIF v_level = 100 THEN
    v_title := 'Legend';
  ELSIF v_level <= 150 THEN
    v_title := 'Mythic I';
  ELSIF v_level <= 200 THEN
    v_title := 'Mythic II';
  ELSE
    v_title := 'Mythic III';
  END IF;

  RETURN QUERY SELECT v_level, v_xp_in_level, v_level_xp, v_title;
END;
$$;

-- =====================================================
-- 2. UPDATE get_xp_title FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION get_xp_title(p_level INTEGER, p_prestige INTEGER DEFAULT 0)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF p_level <= 10 THEN
    RETURN 'Novice';
  ELSIF p_level <= 25 THEN
    RETURN 'Apprentice';
  ELSIF p_level <= 50 THEN
    RETURN 'Athlete';
  ELSIF p_level <= 75 THEN
    RETURN 'Elite';
  ELSIF p_level <= 99 THEN
    RETURN 'Master';
  ELSIF p_level = 100 AND p_prestige = 0 THEN
    RETURN 'Legend';
  ELSIF p_level <= 150 THEN
    RETURN 'Mythic I';
  ELSIF p_level <= 200 THEN
    RETURN 'Mythic II';
  ELSE
    RETURN 'Mythic III';
  END IF;
END;
$$;

-- =====================================================
-- 3. ADD MILESTONE REWARDS FOR LEVELS 101-250
-- =====================================================

-- Add new milestone rewards for Mythic tiers
INSERT INTO level_rewards (level, reward_type, reward_value, description)
VALUES
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
-- 4. UPDATE user_xp TABLE TO SUPPORT HIGHER LEVELS
-- =====================================================

-- Add check constraint for new max level (if not exists)
DO $$
BEGIN
  -- Remove old constraint if exists
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_xp_current_level_check') THEN
    ALTER TABLE user_xp DROP CONSTRAINT user_xp_current_level_check;
  END IF;

  -- Add new constraint
  ALTER TABLE user_xp ADD CONSTRAINT user_xp_current_level_check
    CHECK (current_level >= 1 AND current_level <= 250);
EXCEPTION WHEN OTHERS THEN
  -- Constraint may not exist or already at correct value
  NULL;
END;
$$;

-- =====================================================
-- 5. CREATE FUNCTION TO GET LEVEL INFO
-- =====================================================

CREATE OR REPLACE FUNCTION get_level_info(p_level INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_xp_needed INTEGER;
  v_title TEXT;
  v_total_xp_to_reach INTEGER := 0;
  v_i INTEGER;
  v_level_xp INTEGER;
BEGIN
  -- Calculate XP needed for the given level
  IF p_level <= 10 THEN
    v_xp_needed := 50;
    v_title := 'Novice';
  ELSIF p_level <= 25 THEN
    v_xp_needed := 100;
    v_title := 'Apprentice';
  ELSIF p_level <= 50 THEN
    v_xp_needed := 150;
    v_title := 'Athlete';
  ELSIF p_level <= 75 THEN
    v_xp_needed := 200;
    v_title := 'Elite';
  ELSIF p_level <= 99 THEN
    v_xp_needed := 250;
    v_title := 'Master';
  ELSIF p_level = 100 THEN
    v_xp_needed := 300;
    v_title := 'Legend';
  ELSIF p_level <= 150 THEN
    v_xp_needed := 350;
    v_title := 'Mythic I';
  ELSIF p_level <= 200 THEN
    v_xp_needed := 400;
    v_title := 'Mythic II';
  ELSE
    v_xp_needed := 500;
    v_title := 'Mythic III';
  END IF;

  -- Calculate total XP to reach this level
  FOR v_i IN 1..(p_level - 1) LOOP
    IF v_i <= 10 THEN
      v_level_xp := 50;
    ELSIF v_i <= 25 THEN
      v_level_xp := 100;
    ELSIF v_i <= 50 THEN
      v_level_xp := 150;
    ELSIF v_i <= 75 THEN
      v_level_xp := 200;
    ELSIF v_i <= 99 THEN
      v_level_xp := 250;
    ELSIF v_i = 100 THEN
      v_level_xp := 300;
    ELSIF v_i <= 150 THEN
      v_level_xp := 350;
    ELSIF v_i <= 200 THEN
      v_level_xp := 400;
    ELSE
      v_level_xp := 500;
    END IF;
    v_total_xp_to_reach := v_total_xp_to_reach + v_level_xp;
  END LOOP;

  RETURN jsonb_build_object(
    'level', p_level,
    'title', v_title,
    'xp_to_next_level', v_xp_needed,
    'total_xp_to_reach', v_total_xp_to_reach
  );
END;
$$;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- This migration extends the level progression to 250 levels:
--
-- Level Tiers:
-- - Levels 1-10 (Novice): 50 XP each
-- - Levels 11-25 (Apprentice): 100 XP each
-- - Levels 26-50 (Athlete): 150 XP each
-- - Levels 51-75 (Elite): 200 XP each
-- - Levels 76-99 (Master): 250 XP each
-- - Level 100 (Legend): 300 XP
-- - Levels 101-150 (Mythic I): 350 XP each
-- - Levels 151-200 (Mythic II): 400 XP each
-- - Levels 201-250 (Mythic III): 500 XP each
--
-- Total XP to reach level 250: ~79,550 XP
