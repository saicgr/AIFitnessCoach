-- Migration: World Records (Competitive/Moveable Trophies)
-- Created: 2025-01-19
-- Purpose: Track world records that only one user holds at a time

-- ============================================
-- world_records - Current record holders
-- ============================================
CREATE TABLE IF NOT EXISTS world_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_type TEXT NOT NULL UNIQUE,  -- 'bench_press_max', 'squat_max', 'pushup_reps', etc.
    record_category TEXT NOT NULL,  -- 'single_lift', 'rep_record', 'volume', 'streak', 'social', 'cumulative'
    record_name TEXT NOT NULL,  -- Display name
    record_description TEXT,
    current_holder_id UUID REFERENCES users(id) ON DELETE SET NULL,
    record_value DECIMAL NOT NULL,
    record_unit TEXT NOT NULL,  -- 'lbs', 'kg', 'reps', 'seconds', 'minutes', 'days', 'count'
    exercise_id UUID,  -- For exercise-specific records (can reference exercises table if exists)
    exercise_name TEXT,  -- Exercise name for display
    achieved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    previous_holder_id UUID REFERENCES users(id) ON DELETE SET NULL,
    previous_record DECIMAL,
    icon TEXT DEFAULT '🏆',
    xp_reward INT DEFAULT 500,
    times_broken INT DEFAULT 1,  -- How many times this record has been broken
    requires_verification BOOLEAN DEFAULT false,  -- For top records requiring manual review
    is_verified BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE world_records IS 'Competitive trophies - only ONE user holds each at a time';
COMMENT ON COLUMN world_records.record_type IS 'Unique identifier for record type';
COMMENT ON COLUMN world_records.current_holder_id IS 'User currently holding the record (NULL if no holder yet)';
COMMENT ON COLUMN world_records.requires_verification IS 'If true, record must be manually verified before becoming official';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_world_records_type ON world_records(record_type);
CREATE INDEX IF NOT EXISTS idx_world_records_holder ON world_records(current_holder_id);
CREATE INDEX IF NOT EXISTS idx_world_records_category ON world_records(record_category);

-- Enable Row Level Security
ALTER TABLE world_records ENABLE ROW LEVEL SECURITY;

-- Everyone can view world records
DROP POLICY IF EXISTS world_records_select_policy ON world_records;
CREATE POLICY world_records_select_policy ON world_records
    FOR SELECT
    USING (true);

-- Service role can manage all
DROP POLICY IF EXISTS world_records_service_policy ON world_records;
CREATE POLICY world_records_service_policy ON world_records
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- world_record_history - Historical record holders
-- ============================================
CREATE TABLE IF NOT EXISTS world_record_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_type TEXT NOT NULL,
    holder_id UUID REFERENCES users(id) ON DELETE SET NULL,
    holder_name TEXT,  -- Cached for history display
    record_value DECIMAL NOT NULL,
    held_from TIMESTAMPTZ NOT NULL,
    held_until TIMESTAMPTZ,  -- NULL if current holder
    days_held INT,
    broken_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
    new_record_value DECIMAL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE world_record_history IS 'Historical log of all world record holders';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_world_record_history_type ON world_record_history(record_type);
CREATE INDEX IF NOT EXISTS idx_world_record_history_holder ON world_record_history(holder_id);
CREATE INDEX IF NOT EXISTS idx_world_record_history_held_from ON world_record_history(held_from DESC);

-- Enable Row Level Security
ALTER TABLE world_record_history ENABLE ROW LEVEL SECURITY;

-- Everyone can view history
DROP POLICY IF EXISTS world_record_history_select_policy ON world_record_history;
CREATE POLICY world_record_history_select_policy ON world_record_history
    FOR SELECT
    USING (true);

-- Service role can manage all
DROP POLICY IF EXISTS world_record_history_service_policy ON world_record_history;
CREATE POLICY world_record_history_service_policy ON world_record_history
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- record_challenges - Community reporting for suspicious records
-- ============================================
CREATE TABLE IF NOT EXISTS record_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_id UUID REFERENCES world_records(id) ON DELETE CASCADE,
    record_type TEXT NOT NULL,
    challenger_id UUID REFERENCES users(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,  -- 'impossible_weight', 'bot_behavior', 'multiple_accounts', 'other'
    evidence TEXT,  -- Description of evidence
    status TEXT DEFAULT 'pending',  -- 'pending', 'under_review', 'upheld', 'revoked'
    reviewed_by UUID REFERENCES users(id),  -- Admin who reviewed
    review_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE record_challenges IS 'Community reports of suspicious world records';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_record_challenges_record ON record_challenges(record_id);
CREATE INDEX IF NOT EXISTS idx_record_challenges_status ON record_challenges(status);

-- Enable Row Level Security
ALTER TABLE record_challenges ENABLE ROW LEVEL SECURITY;

-- Users can see challenges they filed
DROP POLICY IF EXISTS record_challenges_select_own_policy ON record_challenges;
CREATE POLICY record_challenges_select_own_policy ON record_challenges
    FOR SELECT
    USING (auth.uid() = challenger_id);

-- Users can create challenges
DROP POLICY IF EXISTS record_challenges_insert_policy ON record_challenges;
CREATE POLICY record_challenges_insert_policy ON record_challenges
    FOR INSERT
    WITH CHECK (auth.uid() = challenger_id);

-- Service role can manage all
DROP POLICY IF EXISTS record_challenges_service_policy ON record_challenges;
CREATE POLICY record_challenges_service_policy ON record_challenges
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- former_champions - Track users who previously held records
-- ============================================
CREATE TABLE IF NOT EXISTS former_champions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    record_type TEXT NOT NULL,
    record_name TEXT NOT NULL,
    record_value DECIMAL NOT NULL,
    held_from TIMESTAMPTZ NOT NULL,
    held_until TIMESTAMPTZ NOT NULL,
    days_held INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, record_type, held_from)
);

COMMENT ON TABLE former_champions IS 'Permanent badge showing users who previously held world records';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_former_champions_user ON former_champions(user_id);
CREATE INDEX IF NOT EXISTS idx_former_champions_type ON former_champions(record_type);

-- Enable Row Level Security
ALTER TABLE former_champions ENABLE ROW LEVEL SECURITY;

-- Users can see their own former champion badges
DROP POLICY IF EXISTS former_champions_select_own_policy ON former_champions;
CREATE POLICY former_champions_select_own_policy ON former_champions
    FOR SELECT
    USING (auth.uid() = user_id);

-- Everyone can see all former champions (for leaderboards)
DROP POLICY IF EXISTS former_champions_select_all_policy ON former_champions;
CREATE POLICY former_champions_select_all_policy ON former_champions
    FOR SELECT
    USING (true);

-- Service role can manage all
DROP POLICY IF EXISTS former_champions_service_policy ON former_champions;
CREATE POLICY former_champions_service_policy ON former_champions
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- Insert default world record types (30 records)
-- ============================================
INSERT INTO world_records (record_type, record_category, record_name, record_description, icon, record_value, record_unit, xp_reward, requires_verification) VALUES
-- Single Lift Records (6)
('bench_press_max', 'single_lift', 'Bench Press World Record', 'Heaviest bench press logged', '🏋️', 0, 'lbs', 500, true),
('squat_max', 'single_lift', 'Squat World Record', 'Heaviest squat logged', '🦵', 0, 'lbs', 500, true),
('deadlift_max', 'single_lift', 'Deadlift World Record', 'Heaviest deadlift logged', '🏋️', 0, 'lbs', 500, true),
('ohp_max', 'single_lift', 'Overhead Press World Record', 'Heaviest overhead press logged', '💪', 0, 'lbs', 500, true),
('row_max', 'single_lift', 'Barbell Row World Record', 'Heaviest barbell row logged', '🏋️', 0, 'lbs', 500, true),
('pulldown_max', 'single_lift', 'Lat Pulldown World Record', 'Heaviest lat pulldown logged', '💪', 0, 'lbs', 500, true),

-- Rep Records (6)
('pushup_reps', 'rep_record', 'Push-up King', 'Most push-ups in one set', '💪', 0, 'reps', 400, false),
('pullup_reps', 'rep_record', 'Pull-up King', 'Most pull-ups in one set', '🏆', 0, 'reps', 400, false),
('squat_reps', 'rep_record', 'Squat Rep King', 'Most bodyweight squats in one set', '🦵', 0, 'reps', 400, false),
('dip_reps', 'rep_record', 'Dip Champion', 'Most dips in one set', '💪', 0, 'reps', 400, false),
('situp_reps', 'rep_record', 'Sit-up Superstar', 'Most sit-ups in one set', '🎯', 0, 'reps', 400, false),
('plank_duration', 'rep_record', 'Plank Master', 'Longest plank hold', '⏱️', 0, 'seconds', 400, false),

-- Volume Records (6)
('workout_volume_single', 'volume', 'Volume King', 'Highest total weight × reps in single workout', '👑', 0, 'lbs', 400, false),
('reps_single_workout', 'volume', 'Rep Marathon Champion', 'Most total reps in single workout', '🏃', 0, 'reps', 400, false),
('sets_single_workout', 'volume', 'Set Crusher', 'Most sets completed in single workout', '📊', 0, 'sets', 350, false),
('longest_workout', 'volume', 'Iron Man', 'Longest single workout duration', '⏰', 0, 'minutes', 350, false),
('daily_volume', 'volume', 'Daily Destroyer', 'Highest volume in 24 hours', '💥', 0, 'lbs', 450, false),
('weekly_volume', 'volume', 'Weekly Warrior', 'Highest volume in 7 days', '📈', 0, 'lbs', 500, false),

-- Streak Records (4)
('longest_streak', 'streak', 'Streak Legend', 'Longest active workout streak', '🔥', 0, 'days', 750, false),
('perfect_weeks', 'streak', 'Perfect Week Champion', 'Most consecutive perfect weeks', '✨', 0, 'weeks', 600, false),
('early_bird_count', 'streak', 'Early Bird Champion', 'Most 5AM workouts all-time', '🌅', 0, 'workouts', 400, false),
('night_owl_count', 'streak', 'Night Owl Champion', 'Most midnight workouts all-time', '🌙', 0, 'workouts', 400, false),

-- Social Records (4)
('most_reactions', 'social', 'Most Popular', 'Most total reactions received', '❤️', 0, 'reactions', 350, false),
('most_friends', 'social', 'Social Champion', 'Most friends in network', '🤝', 0, 'friends', 350, false),
('challenge_wins', 'social', 'Challenge King', 'Most challenge wins', '🏅', 0, 'wins', 500, false),
('helpful_interactions', 'social', 'Community MVP', 'Most helpful interactions', '🙏', 0, 'interactions', 400, false),

-- Cumulative Records (4)
('total_weight_lifted', 'cumulative', 'Iron Legend', 'Most lifetime weight lifted', '⚖️', 0, 'lbs', 1000, false),
('total_workouts', 'cumulative', 'Workout Warrior', 'Most total workouts completed', '🏆', 0, 'workouts', 750, false),
('highest_level', 'cumulative', 'XP Champion', 'Highest XP level achieved', '⭐', 0, 'level', 500, false),
('monthly_volume', 'cumulative', 'Monthly Monster', 'Highest volume in 30 days', '📅', 0, 'lbs', 600, false)
ON CONFLICT (record_type) DO NOTHING;

-- ============================================
-- Function: Attempt to set a new world record
-- ============================================
CREATE OR REPLACE FUNCTION attempt_world_record(
    p_user_id UUID,
    p_record_type TEXT,
    p_new_value DECIMAL,
    p_exercise_name TEXT DEFAULT NULL
) RETURNS TABLE(
    is_new_record BOOLEAN,
    previous_holder_name TEXT,
    previous_record DECIMAL,
    improvement DECIMAL,
    xp_awarded INT
) AS $$
DECLARE
    v_current_record world_records%ROWTYPE;
    v_previous_holder_name TEXT;
    v_xp INT := 0;
    v_is_new BOOLEAN := false;
    v_improvement DECIMAL := 0;
BEGIN
    -- Get current record
    SELECT * INTO v_current_record
    FROM world_records
    WHERE record_type = p_record_type;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown record type: %', p_record_type;
    END IF;

    -- Check if this beats the current record
    IF p_new_value > v_current_record.record_value THEN
        v_is_new := true;
        v_improvement := p_new_value - v_current_record.record_value;

        -- Get previous holder name
        IF v_current_record.current_holder_id IS NOT NULL THEN
            SELECT name INTO v_previous_holder_name
            FROM users WHERE id = v_current_record.current_holder_id;

            -- Add former champion record for previous holder
            INSERT INTO former_champions (user_id, record_type, record_name, record_value, held_from, held_until, days_held)
            VALUES (
                v_current_record.current_holder_id,
                p_record_type,
                v_current_record.record_name,
                v_current_record.record_value,
                v_current_record.achieved_at,
                NOW(),
                EXTRACT(DAY FROM (NOW() - v_current_record.achieved_at))::INT
            )
            ON CONFLICT (user_id, record_type, held_from) DO NOTHING;

            -- Add to history
            INSERT INTO world_record_history (record_type, holder_id, holder_name, record_value, held_from, held_until, days_held, broken_by_id, new_record_value)
            VALUES (
                p_record_type,
                v_current_record.current_holder_id,
                v_previous_holder_name,
                v_current_record.record_value,
                v_current_record.achieved_at,
                NOW(),
                EXTRACT(DAY FROM (NOW() - v_current_record.achieved_at))::INT,
                p_user_id,
                p_new_value
            );
        END IF;

        -- Update world record
        UPDATE world_records
        SET
            current_holder_id = p_user_id,
            record_value = p_new_value,
            previous_holder_id = v_current_record.current_holder_id,
            previous_record = v_current_record.record_value,
            achieved_at = NOW(),
            exercise_name = COALESCE(p_exercise_name, exercise_name),
            times_broken = times_broken + 1,
            is_verified = CASE WHEN requires_verification THEN false ELSE true END,
            updated_at = NOW()
        WHERE record_type = p_record_type;

        -- Award XP
        v_xp := v_current_record.xp_reward;

        -- Award XP to user
        PERFORM award_xp(p_user_id, v_xp, 'world_record', p_record_type, 'New world record: ' || v_current_record.record_name, false);
    END IF;

    RETURN QUERY SELECT v_is_new, v_previous_holder_name, v_current_record.record_value, v_improvement, v_xp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Get all world records with holder info
-- ============================================
CREATE OR REPLACE FUNCTION get_world_records()
RETURNS TABLE(
    record_type TEXT,
    record_category TEXT,
    record_name TEXT,
    record_description TEXT,
    icon TEXT,
    record_value DECIMAL,
    record_unit TEXT,
    current_holder_id UUID,
    holder_name TEXT,
    holder_avatar TEXT,
    achieved_at TIMESTAMPTZ,
    days_held INT,
    times_broken INT,
    is_verified BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        wr.record_type,
        wr.record_category,
        wr.record_name,
        wr.record_description,
        wr.icon,
        wr.record_value,
        wr.record_unit,
        wr.current_holder_id,
        u.name as holder_name,
        u.avatar_url as holder_avatar,
        wr.achieved_at,
        EXTRACT(DAY FROM (NOW() - wr.achieved_at))::INT as days_held,
        wr.times_broken,
        wr.is_verified
    FROM world_records wr
    LEFT JOIN users u ON u.id = wr.current_holder_id
    ORDER BY wr.record_category, wr.record_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Get user's world records held
-- ============================================
CREATE OR REPLACE FUNCTION get_user_world_records(p_user_id UUID)
RETURNS TABLE(
    record_type TEXT,
    record_name TEXT,
    record_value DECIMAL,
    record_unit TEXT,
    achieved_at TIMESTAMPTZ,
    days_held INT,
    is_current BOOLEAN
) AS $$
BEGIN
    -- Current records
    RETURN QUERY
    SELECT
        wr.record_type,
        wr.record_name,
        wr.record_value,
        wr.record_unit,
        wr.achieved_at,
        EXTRACT(DAY FROM (NOW() - wr.achieved_at))::INT as days_held,
        true as is_current
    FROM world_records wr
    WHERE wr.current_holder_id = p_user_id
    UNION ALL
    -- Former records
    SELECT
        fc.record_type,
        fc.record_name,
        fc.record_value,
        'lbs' as record_unit,  -- Default unit
        fc.held_from as achieved_at,
        fc.days_held,
        false as is_current
    FROM former_champions fc
    WHERE fc.user_id = p_user_id
    ORDER BY is_current DESC, achieved_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- View: World records leaderboard
-- ============================================
CREATE OR REPLACE VIEW world_records_leaderboard AS
SELECT
    wr.record_type,
    wr.record_category,
    wr.record_name,
    wr.icon,
    wr.record_value,
    wr.record_unit,
    u.id as holder_id,
    u.name as holder_name,
    u.avatar_url as holder_avatar,
    wr.achieved_at,
    EXTRACT(DAY FROM (NOW() - wr.achieved_at))::INT as days_held,
    wr.is_verified
FROM world_records wr
LEFT JOIN users u ON u.id = wr.current_holder_id
WHERE wr.record_value > 0
ORDER BY wr.record_category, wr.record_name;

COMMENT ON VIEW world_records_leaderboard IS 'Displays all world records with current holder info';
