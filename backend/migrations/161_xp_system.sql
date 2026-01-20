-- Migration: XP & Level System
-- Created: 2025-01-19
-- Purpose: Add XP tracking, level progression, and prestige system for trophy system

-- ============================================
-- user_xp - Main XP tracking per user
-- ============================================
CREATE TABLE IF NOT EXISTS user_xp (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_xp BIGINT DEFAULT 0,
    current_level INT DEFAULT 1,
    xp_to_next_level INT DEFAULT 1000,
    xp_in_current_level INT DEFAULT 0,
    prestige_level INT DEFAULT 0,
    title TEXT DEFAULT 'Novice',
    trust_level INT DEFAULT 1,  -- Anti-fraud: 1=new, 2=verified, 3=trusted
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

COMMENT ON TABLE user_xp IS 'Tracks XP, level, and prestige for each user';
COMMENT ON COLUMN user_xp.total_xp IS 'Lifetime XP earned';
COMMENT ON COLUMN user_xp.current_level IS 'Current level (1-100+)';
COMMENT ON COLUMN user_xp.xp_to_next_level IS 'XP needed to reach next level';
COMMENT ON COLUMN user_xp.xp_in_current_level IS 'XP progress within current level';
COMMENT ON COLUMN user_xp.prestige_level IS 'Prestige level (after level 100)';
COMMENT ON COLUMN user_xp.title IS 'Title based on level (Novice, Apprentice, Athlete, Elite, Master, Legend, Mythic)';
COMMENT ON COLUMN user_xp.trust_level IS 'Anti-fraud trust level: 1=new user, 2=10+ legit workouts, 3=50+ legit workouts';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_xp_user_id ON user_xp(user_id);
CREATE INDEX IF NOT EXISTS idx_user_xp_level ON user_xp(current_level DESC);
CREATE INDEX IF NOT EXISTS idx_user_xp_total_xp ON user_xp(total_xp DESC);

-- Enable Row Level Security
ALTER TABLE user_xp ENABLE ROW LEVEL SECURITY;

-- Users can see their own XP
DROP POLICY IF EXISTS user_xp_select_policy ON user_xp;
CREATE POLICY user_xp_select_policy ON user_xp
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can also see others' XP (for leaderboards)
DROP POLICY IF EXISTS user_xp_select_all_policy ON user_xp;
CREATE POLICY user_xp_select_all_policy ON user_xp
    FOR SELECT
    USING (true);

-- Service role can manage all
DROP POLICY IF EXISTS user_xp_service_policy ON user_xp;
CREATE POLICY user_xp_service_policy ON user_xp
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- xp_transactions - History of all XP changes
-- ============================================
CREATE TABLE IF NOT EXISTS xp_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    xp_amount INT NOT NULL,
    source TEXT NOT NULL,  -- 'workout', 'achievement', 'pr', 'streak', 'challenge', 'meal_log', 'weight_log', 'photo'
    source_id TEXT,  -- Reference to source record (workout_id, achievement_id, etc.)
    description TEXT,
    is_verified BOOLEAN DEFAULT false,  -- Anti-fraud: verified via health app
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE xp_transactions IS 'Audit log of all XP earned/deducted';
COMMENT ON COLUMN xp_transactions.source IS 'Source of XP: workout, achievement, pr, streak, challenge, meal_log, weight_log, photo';
COMMENT ON COLUMN xp_transactions.is_verified IS 'Whether XP source was verified via health app integration';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_id ON xp_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_source ON xp_transactions(source);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_created_at ON xp_transactions(created_at DESC);

-- Enable Row Level Security
ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;

-- Users can see their own XP history
DROP POLICY IF EXISTS xp_transactions_select_policy ON xp_transactions;
CREATE POLICY xp_transactions_select_policy ON xp_transactions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS xp_transactions_service_policy ON xp_transactions;
CREATE POLICY xp_transactions_service_policy ON xp_transactions
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- Function: Calculate level from XP
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

    -- Level progression:
    -- Levels 1-10: 1,000 XP each (10,000 total)
    -- Levels 11-25: 2,500 XP each (47,500 cumulative)
    -- Levels 26-50: 7,500 XP each (235,000 cumulative)
    -- Levels 51-75: 15,000 XP each (610,000 cumulative)
    -- Levels 76-99: 35,000 XP each (1,450,000 cumulative)
    -- Level 100: 100,000 XP (1,550,000 cumulative)
    -- Prestige levels: 150,000 XP each

    WHILE remaining_xp > 0 LOOP
        -- Determine XP needed for current level
        IF current_level <= 10 THEN
            level_xp := 1000;
        ELSIF current_level <= 25 THEN
            level_xp := 2500;
        ELSIF current_level <= 50 THEN
            level_xp := 7500;
        ELSIF current_level <= 75 THEN
            level_xp := 15000;
        ELSIF current_level <= 99 THEN
            level_xp := 35000;
        ELSIF current_level = 100 THEN
            level_xp := 100000;
        ELSE
            -- Prestige levels
            level_xp := 150000;
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
    IF current_level <= 10 THEN
        level_xp := 1000;
    ELSIF current_level <= 25 THEN
        level_xp := 2500;
    ELSIF current_level <= 50 THEN
        level_xp := 7500;
    ELSIF current_level <= 75 THEN
        level_xp := 15000;
    ELSIF current_level <= 99 THEN
        level_xp := 35000;
    ELSIF current_level = 100 THEN
        level_xp := 100000;
    ELSE
        level_xp := 150000;
    END IF;

    RETURN QUERY SELECT current_level, user_title, level_xp, remaining_xp::INT, prestige_lvl;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- Function: Award XP to user
-- ============================================
CREATE OR REPLACE FUNCTION award_xp(
    p_user_id UUID,
    p_xp_amount INT,
    p_source TEXT,
    p_source_id TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_is_verified BOOLEAN DEFAULT false
) RETURNS user_xp AS $$
DECLARE
    v_user_xp user_xp;
    v_new_total BIGINT;
    v_level_info RECORD;
    v_trust_level INT;
    v_xp_multiplier DECIMAL := 1.0;
BEGIN
    -- Get current trust level
    SELECT COALESCE(trust_level, 1) INTO v_trust_level
    FROM user_xp WHERE user_id = p_user_id;

    -- Apply trust level multiplier (anti-fraud)
    -- Trust level 1: 50% XP (new users)
    -- Trust level 2: 100% XP (verified)
    -- Trust level 3: 100% XP + bonus for verified (trusted)
    IF v_trust_level = 1 THEN
        v_xp_multiplier := 0.5;
    ELSIF v_trust_level >= 2 AND p_is_verified THEN
        v_xp_multiplier := 1.2;  -- 20% bonus for verified actions
    END IF;

    -- Insert XP transaction
    INSERT INTO xp_transactions (user_id, xp_amount, source, source_id, description, is_verified)
    VALUES (p_user_id, FLOOR(p_xp_amount * v_xp_multiplier)::INT, p_source, p_source_id, p_description, p_is_verified);

    -- Update or insert user_xp record
    INSERT INTO user_xp (user_id, total_xp)
    VALUES (p_user_id, FLOOR(p_xp_amount * v_xp_multiplier)::INT)
    ON CONFLICT (user_id) DO UPDATE
    SET total_xp = user_xp.total_xp + FLOOR(p_xp_amount * v_xp_multiplier)::INT,
        updated_at = NOW();

    -- Get new total XP
    SELECT total_xp INTO v_new_total FROM user_xp WHERE user_id = p_user_id;

    -- Calculate new level info
    SELECT * INTO v_level_info FROM calculate_level_from_xp(v_new_total);

    -- Update level info
    UPDATE user_xp
    SET current_level = v_level_info.level,
        title = v_level_info.title,
        xp_to_next_level = v_level_info.xp_for_next,
        xp_in_current_level = v_level_info.xp_in_level,
        prestige_level = v_level_info.prestige,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_user_xp;

    RETURN v_user_xp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Get user XP summary
-- ============================================
CREATE OR REPLACE FUNCTION get_user_xp_summary(p_user_id UUID)
RETURNS TABLE(
    total_xp BIGINT,
    current_level INT,
    title TEXT,
    xp_to_next_level INT,
    xp_in_current_level INT,
    progress_percent DECIMAL,
    prestige_level INT,
    trust_level INT,
    rank_position BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ux.total_xp,
        ux.current_level,
        ux.title,
        ux.xp_to_next_level,
        ux.xp_in_current_level,
        CASE
            WHEN ux.xp_to_next_level > 0
            THEN ROUND((ux.xp_in_current_level::DECIMAL / ux.xp_to_next_level) * 100, 1)
            ELSE 100.0
        END as progress_percent,
        ux.prestige_level,
        ux.trust_level,
        (SELECT COUNT(*) + 1 FROM user_xp WHERE user_xp.total_xp > ux.total_xp) as rank_position
    FROM user_xp ux
    WHERE ux.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Trigger: Initialize user_xp on user creation
-- ============================================
CREATE OR REPLACE FUNCTION initialize_user_xp()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_xp (user_id, total_xp, current_level, title)
    VALUES (NEW.id, 0, 1, 'Novice')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_initialize_user_xp ON users;
CREATE TRIGGER trigger_initialize_user_xp
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION initialize_user_xp();

-- ============================================
-- XP Leaderboard view
-- ============================================
CREATE OR REPLACE VIEW xp_leaderboard AS
SELECT
    ux.user_id,
    u.name,
    u.avatar_url,
    ux.total_xp,
    ux.current_level,
    ux.title,
    ux.prestige_level,
    ROW_NUMBER() OVER (ORDER BY ux.total_xp DESC) as rank
FROM user_xp ux
JOIN users u ON u.id = ux.user_id
WHERE ux.total_xp > 0
ORDER BY ux.total_xp DESC;

COMMENT ON VIEW xp_leaderboard IS 'Global XP leaderboard showing top users';
