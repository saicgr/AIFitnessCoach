-- Migration 227: Unified XP Progression System
-- This migration replaces ALL previous XP formulas with a single, retention-optimized 250-level system
--
-- Previous migrations (167, 225) had conflicting formulas. This migration:
-- 1. Drops and recreates calculate_level_from_xp with the correct BIGINT signature
-- 2. Updates get_xp_title with new 11-tier system
-- 3. Recalculates all existing users' levels
--
-- Level Progression (Retention-Optimized):
-- - Levels 1-10 (Beginner): 25-180 XP each (quick early wins)
-- - Levels 11-25 (Novice): 200-500 XP each
-- - Levels 26-50 (Apprentice): 550-1,800 XP each
-- - Levels 51-75 (Athlete): 1,900-4,500 XP each
-- - Levels 76-100 (Elite): 4,800-10,000 XP each
-- - Levels 101-125 (Master): 10,500-23,000 XP each
-- - Levels 126-150 (Champion): 24,000-50,000 XP each
-- - Levels 151-175 (Legend): 52,000-100,000 XP each
-- - Levels 176-200 (Mythic): 100,000 XP each (prestige tier)
-- - Levels 201-225 (Immortal): 100,000 XP each
-- - Levels 226-250 (Transcendent): 100,000 XP each
--
-- Total XP to reach level 250: 10,907,860 XP

-- =====================================================
-- 1. DROP OLD FUNCTIONS (both signatures)
-- =====================================================

DROP FUNCTION IF EXISTS calculate_level_from_xp(BIGINT);
DROP FUNCTION IF EXISTS calculate_level_from_xp(INTEGER);
DROP FUNCTION IF EXISTS get_xp_title(INTEGER, INTEGER);

-- =====================================================
-- 2. CREATE UNIFIED calculate_level_from_xp FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_level_from_xp(p_total_xp BIGINT)
RETURNS TABLE (
  level INT,
  title TEXT,
  xp_for_next INT,
  xp_in_level INT,
  prestige INT
)
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  -- XP required for each level (1-175, then flat 100000 for 176-250)
  xp_table INT[] := ARRAY[
    -- Levels 1-10 (Beginner): Quick early wins
    25, 30, 40, 50, 65, 80, 100, 120, 150, 180,
    -- Levels 11-25 (Novice)
    200, 220, 240, 260, 280, 300, 320, 340, 360, 380, 400, 420, 440, 460, 500,
    -- Levels 26-50 (Apprentice)
    550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1800,
    -- Levels 51-75 (Athlete)
    1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4500,
    -- Levels 76-100 (Elite)
    4800, 5000, 5200, 5400, 5600, 5800, 6000, 6200, 6400, 6600, 6800, 7000, 7200, 7400, 7600, 7800, 8000, 8200, 8400, 8600, 8800, 9000, 9200, 9400, 10000,
    -- Levels 101-125 (Master)
    10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 15500, 16000, 16500, 17000, 17500, 18000, 18500, 19000, 19500, 20000, 20500, 21000, 21500, 22000, 23000,
    -- Levels 126-150 (Champion)
    24000, 25000, 26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 41000, 42000, 43000, 44000, 45000, 46000, 47000, 50000,
    -- Levels 151-175 (Legend)
    52000, 54000, 56000, 58000, 60000, 62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000
  ];
  v_remaining_xp BIGINT;
  v_level INT := 1;
  v_level_xp INT;
  v_xp_in_level INT;
  v_title TEXT;
  v_prestige INT := 0;
BEGIN
  v_remaining_xp := p_total_xp;

  -- Calculate level by consuming XP
  WHILE v_remaining_xp > 0 AND v_level < 250 LOOP
    -- Get XP required for current level
    IF v_level <= 175 THEN
      v_level_xp := xp_table[v_level];
    ELSE
      -- Levels 176-250 are flat 100,000 XP each (prestige tier)
      v_level_xp := 100000;
    END IF;

    IF v_remaining_xp >= v_level_xp THEN
      v_remaining_xp := v_remaining_xp - v_level_xp;
      v_level := v_level + 1;
    ELSE
      EXIT;
    END IF;
  END LOOP;

  -- Store XP progress in current level
  v_xp_in_level := v_remaining_xp::INT;

  -- Calculate XP needed for next level
  IF v_level >= 250 THEN
    v_level_xp := 0; -- Max level reached
  ELSIF v_level <= 175 THEN
    v_level_xp := xp_table[v_level];
  ELSE
    v_level_xp := 100000;
  END IF;

  -- Determine title based on level (11 tiers)
  IF v_level <= 10 THEN
    v_title := 'Beginner';
  ELSIF v_level <= 25 THEN
    v_title := 'Novice';
  ELSIF v_level <= 50 THEN
    v_title := 'Apprentice';
  ELSIF v_level <= 75 THEN
    v_title := 'Athlete';
  ELSIF v_level <= 100 THEN
    v_title := 'Elite';
  ELSIF v_level <= 125 THEN
    v_title := 'Master';
  ELSIF v_level <= 150 THEN
    v_title := 'Champion';
  ELSIF v_level <= 175 THEN
    v_title := 'Legend';
  ELSIF v_level <= 200 THEN
    v_title := 'Mythic';
  ELSIF v_level <= 225 THEN
    v_title := 'Immortal';
  ELSE
    v_title := 'Transcendent';
  END IF;

  RETURN QUERY SELECT v_level, v_title, v_level_xp, v_xp_in_level, v_prestige;
END;
$$;

-- =====================================================
-- 3. CREATE get_xp_title FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION get_xp_title(p_level INTEGER, p_prestige INTEGER DEFAULT 0)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF p_level <= 10 THEN
    RETURN 'Beginner';
  ELSIF p_level <= 25 THEN
    RETURN 'Novice';
  ELSIF p_level <= 50 THEN
    RETURN 'Apprentice';
  ELSIF p_level <= 75 THEN
    RETURN 'Athlete';
  ELSIF p_level <= 100 THEN
    RETURN 'Elite';
  ELSIF p_level <= 125 THEN
    RETURN 'Master';
  ELSIF p_level <= 150 THEN
    RETURN 'Champion';
  ELSIF p_level <= 175 THEN
    RETURN 'Legend';
  ELSIF p_level <= 200 THEN
    RETURN 'Mythic';
  ELSIF p_level <= 225 THEN
    RETURN 'Immortal';
  ELSE
    RETURN 'Transcendent';
  END IF;
END;
$$;

-- =====================================================
-- 4. CREATE get_level_info FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION get_level_info(p_level INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  xp_table INT[] := ARRAY[
    25, 30, 40, 50, 65, 80, 100, 120, 150, 180,
    200, 220, 240, 260, 280, 300, 320, 340, 360, 380, 400, 420, 440, 460, 500,
    550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1800,
    1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4500,
    4800, 5000, 5200, 5400, 5600, 5800, 6000, 6200, 6400, 6600, 6800, 7000, 7200, 7400, 7600, 7800, 8000, 8200, 8400, 8600, 8800, 9000, 9200, 9400, 10000,
    10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 15500, 16000, 16500, 17000, 17500, 18000, 18500, 19000, 19500, 20000, 20500, 21000, 21500, 22000, 23000,
    24000, 25000, 26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 41000, 42000, 43000, 44000, 45000, 46000, 47000, 50000,
    52000, 54000, 56000, 58000, 60000, 62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000
  ];
  v_xp_needed INT;
  v_title TEXT;
  v_total_xp_to_reach BIGINT := 0;
  v_i INT;
BEGIN
  -- Calculate XP needed for the given level
  IF p_level >= 250 THEN
    v_xp_needed := 0; -- Max level
  ELSIF p_level <= 175 THEN
    v_xp_needed := xp_table[p_level];
  ELSE
    v_xp_needed := 100000;
  END IF;

  -- Get title
  v_title := get_xp_title(p_level);

  -- Calculate total XP to reach this level
  FOR v_i IN 1..(p_level - 1) LOOP
    IF v_i <= 175 THEN
      v_total_xp_to_reach := v_total_xp_to_reach + xp_table[v_i];
    ELSE
      v_total_xp_to_reach := v_total_xp_to_reach + 100000;
    END IF;
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
-- 5. RECALCULATE ALL EXISTING USERS' LEVELS
-- =====================================================

DO $$
DECLARE
  user_record RECORD;
  level_info RECORD;
BEGIN
  FOR user_record IN SELECT user_id, total_xp FROM user_xp WHERE total_xp > 0 LOOP
    SELECT * INTO level_info FROM calculate_level_from_xp(user_record.total_xp);

    UPDATE user_xp
    SET current_level = level_info.level,
        title = level_info.title,
        xp_to_next_level = level_info.xp_for_next,
        xp_in_current_level = level_info.xp_in_level,
        prestige_level = level_info.prestige,
        updated_at = NOW()
    WHERE user_id = user_record.user_id;
  END LOOP;

  RAISE NOTICE 'Recalculated levels for all users with XP';
END $$;

-- =====================================================
-- 6. UPDATE user_xp TABLE CONSTRAINTS
-- =====================================================

DO $$
BEGIN
  -- Remove old constraint if exists
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_xp_current_level_check') THEN
    ALTER TABLE user_xp DROP CONSTRAINT user_xp_current_level_check;
  END IF;

  -- Add new constraint for max level 250
  ALTER TABLE user_xp ADD CONSTRAINT user_xp_current_level_check
    CHECK (current_level >= 1 AND current_level <= 250);
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON FUNCTION calculate_level_from_xp(BIGINT) IS
'Unified XP level calculation function. Migration 227 - replaces all previous formulas.
Uses retention-optimized progressive curve with 250 levels across 11 tiers:
Beginner(1-10), Novice(11-25), Apprentice(26-50), Athlete(51-75), Elite(76-100),
Master(101-125), Champion(126-150), Legend(151-175), Mythic(176-200),
Immortal(201-225), Transcendent(226-250).';

COMMENT ON FUNCTION get_xp_title(INTEGER, INTEGER) IS
'Returns the title/tier name for a given level. 11 tiers from Beginner to Transcendent.';

COMMENT ON FUNCTION get_level_info(INTEGER) IS
'Returns detailed level info as JSON including title, XP needed, and cumulative XP to reach level.';
