-- Migration: Rebalance Early XP Levels
-- Created: 2025-01-20
-- Purpose: Make early levels (1-10) more achievable with quick early wins
--
-- Problem: 1000 XP per level for levels 1-10 is too steep for new users
-- Solution: Start with 50 XP for level 2, scale up gradually
--
-- New Level Progression (Engagement-Optimized):
-- Level 2: 50 XP (cumulative: 50) - Day 1: Login + onboarding + workout = Level 2!
-- Level 3: 100 XP (cumulative: 150) - Day 2
-- Level 4: 150 XP (cumulative: 300) - Day 3-4
-- Level 5: 200 XP (cumulative: 500) - First week milestone
-- Level 6: 300 XP (cumulative: 800) - Week 2
-- Level 7: 400 XP (cumulative: 1,200) - Week 2-3
-- Level 8: 500 XP (cumulative: 1,700) - Week 3
-- Level 9: 750 XP (cumulative: 2,450) - Week 4
-- Level 10: 1,000 XP (cumulative: 3,450) - Month 1 milestone
-- Level 11+: 1,500 XP each
-- Level 26+: 5,000 XP each
-- Level 51+: 10,000 XP each
-- Level 76+: 25,000 XP each
-- Level 100: 75,000 XP
-- Prestige: 100,000 XP each

-- ============================================
-- Updated Function: Calculate level from XP
-- ============================================
CREATE OR REPLACE FUNCTION calculate_level_from_xp(total_xp BIGINT)
RETURNS TABLE(level INT, title TEXT, xp_for_next INT, xp_in_level INT, prestige INT) AS $$
DECLARE
    remaining_xp BIGINT;
    current_level INT := 1;
    level_xp INT;
    accumulated_xp BIGINT := 0;
    user_title TEXT := 'Novice';
    prestige_lvl INT := 0;
BEGIN
    remaining_xp := total_xp;

    -- Level progression (engagement-optimized):
    -- Quick early wins to hook users, then gradual scaling
    --
    -- Level 2: 50 XP (Day 1 achievable)
    -- Level 3: 100 XP
    -- Level 4: 150 XP
    -- Level 5: 200 XP (First week)
    -- Level 6: 300 XP
    -- Level 7: 400 XP
    -- Level 8: 500 XP
    -- Level 9: 750 XP
    -- Level 10: 1,000 XP (Month 1)
    -- (Total for levels 1-10: 3,450 XP)
    --
    -- Levels 11-25: 1,500 XP each (22,500 XP for this tier)
    -- Levels 26-50: 5,000 XP each (125,000 XP for this tier)
    -- Levels 51-75: 10,000 XP each (250,000 XP for this tier)
    -- Levels 76-99: 25,000 XP each (600,000 XP for this tier)
    -- Level 100: 75,000 XP
    -- Prestige levels: 100,000 XP each

    WHILE remaining_xp > 0 LOOP
        -- Determine XP needed for current level
        IF current_level = 1 THEN
            level_xp := 50;     -- Level 1 -> 2 (Day 1!)
        ELSIF current_level = 2 THEN
            level_xp := 100;    -- Level 2 -> 3
        ELSIF current_level = 3 THEN
            level_xp := 150;    -- Level 3 -> 4
        ELSIF current_level = 4 THEN
            level_xp := 200;    -- Level 4 -> 5 (Week 1)
        ELSIF current_level = 5 THEN
            level_xp := 300;    -- Level 5 -> 6
        ELSIF current_level = 6 THEN
            level_xp := 400;    -- Level 6 -> 7
        ELSIF current_level = 7 THEN
            level_xp := 500;    -- Level 7 -> 8
        ELSIF current_level = 8 THEN
            level_xp := 750;    -- Level 8 -> 9
        ELSIF current_level = 9 THEN
            level_xp := 1000;   -- Level 9 -> 10 (Month 1)
        ELSIF current_level <= 25 THEN
            level_xp := 1500;   -- Apprentice tier
        ELSIF current_level <= 50 THEN
            level_xp := 5000;   -- Athlete tier
        ELSIF current_level <= 75 THEN
            level_xp := 10000;  -- Elite tier
        ELSIF current_level <= 99 THEN
            level_xp := 25000;  -- Master tier
        ELSIF current_level = 100 THEN
            level_xp := 75000;  -- Legend
        ELSE
            -- Prestige levels
            level_xp := 100000;
        END IF;

        IF remaining_xp >= level_xp THEN
            remaining_xp := remaining_xp - level_xp;
            accumulated_xp := accumulated_xp + level_xp;
            current_level := current_level + 1;

            IF current_level > 100 THEN
                prestige_lvl := prestige_lvl + 1;
            END IF;
        ELSE
            EXIT;
        END IF;
    END LOOP;

    -- Determine title
    IF current_level <= 10 THEN
        user_title := 'Novice';
    ELSIF current_level <= 25 THEN
        user_title := 'Apprentice';
    ELSIF current_level <= 50 THEN
        user_title := 'Athlete';
    ELSIF current_level <= 75 THEN
        user_title := 'Elite';
    ELSIF current_level <= 99 THEN
        user_title := 'Master';
    ELSIF current_level = 100 THEN
        user_title := 'Legend';
    ELSE
        user_title := 'Mythic';
    END IF;

    -- Calculate XP needed for next level
    IF current_level = 1 THEN
        level_xp := 50;
    ELSIF current_level = 2 THEN
        level_xp := 100;
    ELSIF current_level = 3 THEN
        level_xp := 150;
    ELSIF current_level = 4 THEN
        level_xp := 200;
    ELSIF current_level = 5 THEN
        level_xp := 300;
    ELSIF current_level = 6 THEN
        level_xp := 400;
    ELSIF current_level = 7 THEN
        level_xp := 500;
    ELSIF current_level = 8 THEN
        level_xp := 750;
    ELSIF current_level = 9 THEN
        level_xp := 1000;
    ELSIF current_level <= 25 THEN
        level_xp := 1500;
    ELSIF current_level <= 50 THEN
        level_xp := 5000;
    ELSIF current_level <= 75 THEN
        level_xp := 10000;
    ELSIF current_level <= 99 THEN
        level_xp := 25000;
    ELSIF current_level = 100 THEN
        level_xp := 75000;
    ELSE
        level_xp := 100000;
    END IF;

    RETURN QUERY SELECT current_level, user_title, level_xp, remaining_xp::INT, prestige_lvl;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- Recalculate all existing users' levels
-- (in case any users already have XP)
-- ============================================
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
END $$;

COMMENT ON FUNCTION calculate_level_from_xp IS 'Calculates level, title, and progress from total XP. Rebalanced in migration 167 for gradual early level curve.';
