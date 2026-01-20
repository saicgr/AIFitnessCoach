-- Migration: Anti-Fraud & Validation System
-- Created: 2025-01-19
-- Purpose: Fraud prevention for XP, achievements, and world records

-- ============================================
-- xp_audit_log - Track all XP changes for review
-- ============================================
CREATE TABLE IF NOT EXISTS xp_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,  -- 'xp_awarded', 'xp_revoked', 'achievement_earned', 'record_set', 'level_up'
    amount INT,  -- XP amount if applicable
    reason TEXT,
    source_type TEXT,  -- 'workout', 'achievement', 'streak', 'challenge', etc.
    source_id TEXT,  -- Reference to source record
    flags TEXT[],  -- Any fraud flags at time of action
    trust_level INT,
    ip_address INET,
    device_fingerprint TEXT,
    user_agent TEXT,
    is_health_verified BOOLEAN DEFAULT false,
    metadata JSONB,  -- Additional context
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE xp_audit_log IS 'Complete audit trail of all XP and achievement activity';
COMMENT ON COLUMN xp_audit_log.flags IS 'Fraud flags: too_fast, weight_jump, frequency_abuse, bot_pattern, robotic_pattern';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_xp_audit_user ON xp_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_audit_action ON xp_audit_log(action);
CREATE INDEX IF NOT EXISTS idx_xp_audit_created ON xp_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_xp_audit_flags ON xp_audit_log USING GIN(flags);

-- Enable Row Level Security
ALTER TABLE xp_audit_log ENABLE ROW LEVEL SECURITY;

-- Users can see their own audit log
DROP POLICY IF EXISTS xp_audit_select_policy ON xp_audit_log;
CREATE POLICY xp_audit_select_policy ON xp_audit_log
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS xp_audit_service_policy ON xp_audit_log;
CREATE POLICY xp_audit_service_policy ON xp_audit_log
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- fraud_flags - Track suspicious user activity
-- ============================================
CREATE TABLE IF NOT EXISTS fraud_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    flag_type TEXT NOT NULL,  -- 'too_fast', 'weight_jump', 'frequency_abuse', 'bot_pattern', 'multiple_accounts', etc.
    severity TEXT DEFAULT 'warning',  -- 'info', 'warning', 'critical'
    details TEXT,
    source_id TEXT,  -- Related workout/achievement ID
    metadata JSONB,
    auto_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE fraud_flags IS 'Tracks suspicious activity flags for users';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_fraud_flags_user ON fraud_flags(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_flags_type ON fraud_flags(flag_type);
CREATE INDEX IF NOT EXISTS idx_fraud_flags_severity ON fraud_flags(severity);
CREATE INDEX IF NOT EXISTS idx_fraud_flags_unresolved ON fraud_flags(user_id) WHERE resolved_at IS NULL;

-- Enable Row Level Security
ALTER TABLE fraud_flags ENABLE ROW LEVEL SECURITY;

-- Service role only
DROP POLICY IF EXISTS fraud_flags_service_policy ON fraud_flags;
CREATE POLICY fraud_flags_service_policy ON fraud_flags
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- user_penalties - Track warnings, probations, bans
-- ============================================
CREATE TABLE IF NOT EXISTS user_penalties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    penalty_type TEXT NOT NULL,  -- 'warning', 'xp_reduction', 'probation', 'leaderboard_ban', 'account_suspension'
    reason TEXT NOT NULL,
    details JSONB,  -- Additional info like XP amount revoked
    duration_days INT,  -- NULL for permanent
    starts_at TIMESTAMPTZ DEFAULT NOW(),
    ends_at TIMESTAMPTZ,  -- NULL for permanent
    is_active BOOLEAN DEFAULT true,
    issued_by UUID,  -- Admin who issued
    appealed BOOLEAN DEFAULT false,
    appeal_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE user_penalties IS 'Tracks penalties issued to users for violations';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_penalties_user ON user_penalties(user_id);
CREATE INDEX IF NOT EXISTS idx_user_penalties_active ON user_penalties(user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_penalties_type ON user_penalties(penalty_type);

-- Enable Row Level Security
ALTER TABLE user_penalties ENABLE ROW LEVEL SECURITY;

-- Users can see their own penalties
DROP POLICY IF EXISTS user_penalties_select_policy ON user_penalties;
CREATE POLICY user_penalties_select_policy ON user_penalties
    FOR SELECT
    USING (auth.uid() = user_id);

-- Service role can manage all
DROP POLICY IF EXISTS user_penalties_service_policy ON user_penalties;
CREATE POLICY user_penalties_service_policy ON user_penalties
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- workout_validation_limits - Define realistic limits
-- ============================================
CREATE TABLE IF NOT EXISTS workout_validation_limits (
    id VARCHAR(50) PRIMARY KEY,
    exercise_category TEXT NOT NULL,  -- 'barbell', 'dumbbell', 'bodyweight', 'machine', 'cardio'
    max_weight_lbs INT,  -- Maximum realistic weight
    max_reps_per_set INT,  -- Maximum reps in a single set
    max_sets_per_workout INT,  -- Maximum sets in one workout
    max_duration_seconds INT,  -- For timed exercises (plank, etc.)
    min_rest_seconds INT,  -- Minimum realistic rest between sets
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE workout_validation_limits IS 'Defines realistic limits for workout validation';

-- Insert default limits
INSERT INTO workout_validation_limits (id, exercise_category, max_weight_lbs, max_reps_per_set, max_sets_per_workout, max_duration_seconds) VALUES
('barbell_compound', 'barbell', 1100, 100, 20, NULL),  -- World record deadlift is ~1100 lbs
('barbell_isolation', 'barbell', 500, 100, 20, NULL),
('dumbbell', 'dumbbell', 200, 100, 25, NULL),  -- Per dumbbell
('bodyweight', 'bodyweight', NULL, 500, 30, NULL),  -- Push-ups, pull-ups, etc.
('machine', 'machine', 800, 100, 20, NULL),
('cardio', 'cardio', NULL, NULL, NULL, 14400),  -- 4 hours max
('plank', 'isometric', NULL, NULL, 10, 600),  -- 10 minutes max plank
('general', 'general', 1100, 500, 50, 14400)  -- General fallback limits
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Function: Validate workout data
-- ============================================
CREATE OR REPLACE FUNCTION validate_workout_data(
    p_user_id UUID,
    p_workout_data JSONB
) RETURNS TABLE(
    is_valid BOOLEAN,
    flags TEXT[],
    warnings TEXT[]
) AS $$
DECLARE
    v_flags TEXT[] := '{}';
    v_warnings TEXT[] := '{}';
    v_workouts_today INT;
    v_last_workout_at TIMESTAMPTZ;
    v_user_trust INT;
    v_account_age INT;
    v_exercise JSONB;
    v_limits workout_validation_limits%ROWTYPE;
BEGIN
    -- Get user info
    SELECT trust_level INTO v_user_trust FROM user_xp WHERE user_id = p_user_id;
    v_user_trust := COALESCE(v_user_trust, 1);

    SELECT EXTRACT(DAY FROM (NOW() - created_at))::INT INTO v_account_age
    FROM users WHERE id = p_user_id;

    -- Check workouts today
    SELECT COUNT(*) INTO v_workouts_today
    FROM workouts
    WHERE user_id = p_user_id
    AND DATE(completed_at) = DATE(NOW())
    AND status = 'completed';

    IF v_workouts_today >= 3 THEN
        v_flags := array_append(v_flags, 'frequency_abuse');
    END IF;

    -- Check last workout time (minimum 30 min gap)
    SELECT MAX(completed_at) INTO v_last_workout_at
    FROM workouts
    WHERE user_id = p_user_id AND status = 'completed';

    IF v_last_workout_at IS NOT NULL AND (NOW() - v_last_workout_at) < INTERVAL '30 minutes' THEN
        v_flags := array_append(v_flags, 'too_fast');
    END IF;

    -- Validate exercises if provided
    IF p_workout_data ? 'exercises' THEN
        FOR v_exercise IN SELECT * FROM jsonb_array_elements(p_workout_data->'exercises')
        LOOP
            -- Get limits for exercise type
            SELECT * INTO v_limits FROM workout_validation_limits WHERE id = 'general';

            -- Check weight
            IF (v_exercise->>'weight')::INT > COALESCE(v_limits.max_weight_lbs, 1100) THEN
                v_flags := array_append(v_flags, 'impossible_weight');
            END IF;

            -- Check reps
            IF (v_exercise->>'reps')::INT > COALESCE(v_limits.max_reps_per_set, 500) THEN
                v_flags := array_append(v_flags, 'impossible_reps');
            END IF;
        END LOOP;
    END IF;

    -- Check for new user with suspicious activity
    IF v_account_age < 7 AND array_length(v_flags, 1) > 0 THEN
        v_flags := array_append(v_flags, 'new_user_suspicious');
    END IF;

    -- Return validation result
    RETURN QUERY SELECT
        (array_length(v_flags, 1) IS NULL OR array_length(v_flags, 1) = 0) as is_valid,
        v_flags,
        v_warnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Update user trust level
-- ============================================
CREATE OR REPLACE FUNCTION update_trust_level(p_user_id UUID) RETURNS INT AS $$
DECLARE
    v_completed_workouts INT;
    v_account_age INT;
    v_flag_count INT;
    v_new_trust INT := 1;
    v_health_verified BOOLEAN := false;
BEGIN
    -- Count completed workouts
    SELECT COUNT(*) INTO v_completed_workouts
    FROM workouts
    WHERE user_id = p_user_id AND status = 'completed';

    -- Get account age
    SELECT EXTRACT(DAY FROM (NOW() - created_at))::INT INTO v_account_age
    FROM users WHERE id = p_user_id;

    -- Count unresolved fraud flags
    SELECT COUNT(*) INTO v_flag_count
    FROM fraud_flags
    WHERE user_id = p_user_id AND resolved_at IS NULL;

    -- Check for health app verification (would be set elsewhere)
    -- v_health_verified := EXISTS (SELECT 1 FROM user_health_connections WHERE user_id = p_user_id AND is_active = true);

    -- Calculate trust level
    IF v_flag_count > 3 THEN
        v_new_trust := 1;  -- Downgrade if too many flags
    ELSIF v_completed_workouts >= 50 AND v_account_age >= 60 THEN
        v_new_trust := 3;  -- Trusted
    ELSIF v_completed_workouts >= 10 AND v_account_age >= 14 THEN
        v_new_trust := 2;  -- Verified
    ELSE
        v_new_trust := 1;  -- New
    END IF;

    -- Health verification bonus
    IF v_health_verified AND v_new_trust < 3 THEN
        v_new_trust := v_new_trust + 1;
    END IF;

    -- Update user_xp
    UPDATE user_xp
    SET trust_level = v_new_trust, updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN v_new_trust;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Log XP action
-- ============================================
CREATE OR REPLACE FUNCTION log_xp_action(
    p_user_id UUID,
    p_action TEXT,
    p_amount INT DEFAULT NULL,
    p_reason TEXT DEFAULT NULL,
    p_source_type TEXT DEFAULT NULL,
    p_source_id TEXT DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_device_fingerprint TEXT DEFAULT NULL,
    p_is_verified BOOLEAN DEFAULT false
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
    v_trust_level INT;
    v_flags TEXT[] := '{}';
BEGIN
    -- Get current trust level
    SELECT trust_level INTO v_trust_level FROM user_xp WHERE user_id = p_user_id;

    -- Check for suspicious patterns
    IF p_source_type = 'workout' THEN
        SELECT flags INTO v_flags FROM validate_workout_data(p_user_id, '{}'::JSONB);
    END IF;

    -- Create audit log entry
    INSERT INTO xp_audit_log (
        user_id, action, amount, reason, source_type, source_id,
        flags, trust_level, ip_address, device_fingerprint, is_health_verified
    ) VALUES (
        p_user_id, p_action, p_amount, p_reason, p_source_type, p_source_id,
        v_flags, v_trust_level, p_ip_address, p_device_fingerprint, p_is_verified
    )
    RETURNING id INTO v_log_id;

    -- Create fraud flag if suspicious
    IF array_length(v_flags, 1) > 0 THEN
        INSERT INTO fraud_flags (user_id, flag_type, severity, details, source_id)
        VALUES (
            p_user_id,
            v_flags[1],  -- Primary flag
            CASE WHEN array_length(v_flags, 1) > 2 THEN 'critical' ELSE 'warning' END,
            'Suspicious activity detected: ' || array_to_string(v_flags, ', '),
            p_source_id
        );
    END IF;

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Revoke XP (for fraud)
-- ============================================
CREATE OR REPLACE FUNCTION revoke_xp(
    p_user_id UUID,
    p_amount INT,
    p_reason TEXT,
    p_admin_id UUID DEFAULT NULL
) RETURNS user_xp AS $$
DECLARE
    v_user_xp user_xp%ROWTYPE;
    v_level_info RECORD;
BEGIN
    -- Update XP (ensure it doesn't go below 0)
    UPDATE user_xp
    SET total_xp = GREATEST(0, total_xp - p_amount),
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Recalculate level
    SELECT total_xp INTO v_user_xp FROM user_xp WHERE user_id = p_user_id;
    SELECT * INTO v_level_info FROM calculate_level_from_xp(v_user_xp.total_xp);

    UPDATE user_xp
    SET current_level = v_level_info.level,
        title = v_level_info.title,
        xp_to_next_level = v_level_info.xp_for_next,
        xp_in_current_level = v_level_info.xp_in_level,
        prestige_level = v_level_info.prestige
    WHERE user_id = p_user_id
    RETURNING * INTO v_user_xp;

    -- Log the revocation
    PERFORM log_xp_action(p_user_id, 'xp_revoked', -p_amount, p_reason, 'admin', p_admin_id::TEXT);

    -- Create penalty record
    INSERT INTO user_penalties (user_id, penalty_type, reason, details, issued_by)
    VALUES (p_user_id, 'xp_reduction', p_reason, jsonb_build_object('amount', p_amount), p_admin_id);

    RETURN v_user_xp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Check if user is on probation
-- ============================================
CREATE OR REPLACE FUNCTION is_user_on_probation(p_user_id UUID) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_penalties
        WHERE user_id = p_user_id
        AND penalty_type IN ('probation', 'leaderboard_ban', 'account_suspension')
        AND is_active = true
        AND (ends_at IS NULL OR ends_at > NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function: Check if user can participate in world records
-- ============================================
CREATE OR REPLACE FUNCTION can_participate_in_records(p_user_id UUID) RETURNS BOOLEAN AS $$
DECLARE
    v_trust_level INT;
    v_account_age INT;
    v_on_probation BOOLEAN;
BEGIN
    -- Get trust level
    SELECT trust_level INTO v_trust_level FROM user_xp WHERE user_id = p_user_id;
    v_trust_level := COALESCE(v_trust_level, 1);

    -- Get account age
    SELECT EXTRACT(DAY FROM (NOW() - created_at))::INT INTO v_account_age
    FROM users WHERE id = p_user_id;

    -- Check probation
    v_on_probation := is_user_on_probation(p_user_id);

    -- Must have trust level 2+, 30+ day account, not on probation
    RETURN v_trust_level >= 2 AND v_account_age >= 30 AND NOT v_on_probation;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Trigger: Validate workout before insert
-- ============================================
CREATE OR REPLACE FUNCTION validate_workout_insert()
RETURNS TRIGGER AS $$
DECLARE
    v_workouts_today INT;
BEGIN
    -- Reject workouts with future dates
    IF NEW.completed_at > NOW() THEN
        RAISE EXCEPTION 'Cannot log future workouts';
    END IF;

    -- Reject workouts more than 7 days old
    IF NEW.completed_at < NOW() - INTERVAL '7 days' THEN
        RAISE EXCEPTION 'Cannot log workouts older than 7 days';
    END IF;

    -- Check daily limit (3 workouts max)
    SELECT COUNT(*) INTO v_workouts_today
    FROM workouts
    WHERE user_id = NEW.user_id
    AND DATE(completed_at) = DATE(NEW.completed_at)
    AND status = 'completed';

    IF v_workouts_today >= 3 THEN
        RAISE EXCEPTION 'Maximum 3 workouts per day';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Only create trigger if workouts table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workouts') THEN
        DROP TRIGGER IF EXISTS trigger_validate_workout_insert ON workouts;
        CREATE TRIGGER trigger_validate_workout_insert
            BEFORE INSERT ON workouts
            FOR EACH ROW
            WHEN (NEW.status = 'completed')
            EXECUTE FUNCTION validate_workout_insert();
    END IF;
END $$;

-- ============================================
-- View: Admin fraud dashboard
-- ============================================
CREATE OR REPLACE VIEW admin_fraud_dashboard AS
SELECT
    ff.user_id,
    u.name,
    u.email,
    COUNT(DISTINCT ff.id) as total_flags,
    COUNT(DISTINCT ff.id) FILTER (WHERE ff.severity = 'critical') as critical_flags,
    COUNT(DISTINCT ff.id) FILTER (WHERE ff.resolved_at IS NULL) as unresolved_flags,
    ux.trust_level,
    ux.current_level,
    ux.total_xp,
    MAX(ff.created_at) as last_flag_at,
    bool_or(up.is_active) as has_active_penalty
FROM fraud_flags ff
JOIN users u ON u.id = ff.user_id
LEFT JOIN user_xp ux ON ux.user_id = ff.user_id
LEFT JOIN user_penalties up ON up.user_id = ff.user_id AND up.is_active = true
GROUP BY ff.user_id, u.name, u.email, ux.trust_level, ux.current_level, ux.total_xp
HAVING COUNT(DISTINCT ff.id) FILTER (WHERE ff.resolved_at IS NULL) > 0
ORDER BY critical_flags DESC, total_flags DESC;

COMMENT ON VIEW admin_fraud_dashboard IS 'Admin view of users with fraud flags for review';

-- ============================================
-- Scheduled job to update trust levels (run daily)
-- ============================================
-- This would be called by a cron job or scheduled task
CREATE OR REPLACE FUNCTION scheduled_update_trust_levels() RETURNS VOID AS $$
DECLARE
    v_user RECORD;
BEGIN
    FOR v_user IN SELECT user_id FROM user_xp LOOP
        PERFORM update_trust_level(v_user.user_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Function to expire old penalties
-- ============================================
CREATE OR REPLACE FUNCTION expire_old_penalties() RETURNS VOID AS $$
BEGIN
    UPDATE user_penalties
    SET is_active = false, updated_at = NOW()
    WHERE is_active = true
    AND ends_at IS NOT NULL
    AND ends_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
