-- Migration: 101_branded_programs.sql
-- Description: Create branded workout programs and user program assignments
-- Created: 2025-12-30

-- ============================================================================
-- BRANDED PROGRAMS TABLE
-- ============================================================================
-- Stores pre-designed workout programs with branding, theming, and structure

CREATE TABLE IF NOT EXISTS branded_programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Program Identity
    name TEXT NOT NULL UNIQUE,
    tagline TEXT,
    description TEXT,

    -- Classification
    category TEXT NOT NULL CHECK (category IN (
        'strength', 'hypertrophy', 'endurance', 'athletic',
        'fat_loss', 'general_fitness', 'bodyweight', 'powerbuilding'
    )),
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN (
        'beginner', 'intermediate', 'advanced', 'all_levels'
    )),

    -- Structure
    duration_weeks INTEGER NOT NULL CHECK (duration_weeks > 0 AND duration_weeks <= 52),
    sessions_per_week INTEGER NOT NULL CHECK (sessions_per_week >= 1 AND sessions_per_week <= 7),
    split_type TEXT NOT NULL CHECK (split_type IN (
        'full_body', 'upper_lower', 'push_pull_legs', 'push_pull',
        'bro_split', 'arnold_split', 'custom', 'bodypart'
    )),

    -- Goals (array of target outcomes)
    goals TEXT[] NOT NULL DEFAULT '{}',

    -- UI/Theming
    icon_name TEXT DEFAULT 'fitness_center',
    color_hex TEXT DEFAULT '#4A90A4' CHECK (color_hex ~ '^#[0-9A-Fa-f]{6}$'),

    -- Flags
    is_featured BOOLEAN DEFAULT false,
    is_premium BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,

    -- Equipment requirements (for filtering)
    requires_gym BOOLEAN DEFAULT true,
    minimum_equipment TEXT[] DEFAULT '{}',

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- USER PROGRAM ASSIGNMENTS TABLE
-- ============================================================================
-- Tracks which programs users are enrolled in and their progress

CREATE TABLE IF NOT EXISTS user_program_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- User reference
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Program reference (nullable for fully custom programs)
    branded_program_id UUID REFERENCES branded_programs(id) ON DELETE SET NULL,

    -- Custom naming
    custom_program_name TEXT,  -- User's personalized name for their program

    -- Timeline
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    target_end_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    paused_at TIMESTAMP WITH TIME ZONE,

    -- Status
    is_active BOOLEAN DEFAULT true,
    status TEXT DEFAULT 'active' CHECK (status IN (
        'active', 'paused', 'completed', 'abandoned', 'scheduled'
    )),

    -- Progress tracking
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    workouts_completed INTEGER DEFAULT 0 CHECK (workouts_completed >= 0),
    total_workouts INTEGER CHECK (total_workouts >= 0),
    current_week INTEGER DEFAULT 1 CHECK (current_week >= 1),

    -- Customization
    difficulty_adjustment INTEGER DEFAULT 0 CHECK (difficulty_adjustment >= -2 AND difficulty_adjustment <= 2),
    notes TEXT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_progress CHECK (
        workouts_completed <= COALESCE(total_workouts, workouts_completed)
    ),
    CONSTRAINT has_program_identity CHECK (
        branded_program_id IS NOT NULL OR custom_program_name IS NOT NULL
    )
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Branded programs indexes
CREATE INDEX IF NOT EXISTS idx_branded_programs_category ON branded_programs(category);
CREATE INDEX IF NOT EXISTS idx_branded_programs_difficulty ON branded_programs(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_branded_programs_featured ON branded_programs(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_branded_programs_premium ON branded_programs(is_premium);
CREATE INDEX IF NOT EXISTS idx_branded_programs_active ON branded_programs(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_branded_programs_duration ON branded_programs(duration_weeks);
CREATE INDEX IF NOT EXISTS idx_branded_programs_sessions ON branded_programs(sessions_per_week);
CREATE INDEX IF NOT EXISTS idx_branded_programs_split ON branded_programs(split_type);

-- User program assignments indexes
CREATE INDEX IF NOT EXISTS idx_user_program_assignments_user ON user_program_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_program_assignments_program ON user_program_assignments(branded_program_id);
CREATE INDEX IF NOT EXISTS idx_user_program_assignments_active ON user_program_assignments(user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_program_assignments_status ON user_program_assignments(status);
CREATE INDEX IF NOT EXISTS idx_user_program_assignments_started ON user_program_assignments(started_at);
CREATE INDEX IF NOT EXISTS idx_user_program_assignments_completed ON user_program_assignments(completed_at) WHERE completed_at IS NOT NULL;

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_user_active_programs ON user_program_assignments(user_id, branded_program_id, is_active)
    WHERE is_active = true;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on both tables
ALTER TABLE branded_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_program_assignments ENABLE ROW LEVEL SECURITY;

-- Branded programs policies (read-only for all authenticated users)
CREATE POLICY "branded_programs_select_policy" ON branded_programs
    FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Admin policy for branded programs (full access for service role)
CREATE POLICY "branded_programs_admin_policy" ON branded_programs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- User program assignments policies
CREATE POLICY "user_program_assignments_select_own" ON user_program_assignments
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "user_program_assignments_insert_own" ON user_program_assignments
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_program_assignments_update_own" ON user_program_assignments
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_program_assignments_delete_own" ON user_program_assignments
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Service role full access for user program assignments
CREATE POLICY "user_program_assignments_admin_policy" ON user_program_assignments
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update timestamp trigger for branded_programs
CREATE OR REPLACE FUNCTION update_branded_programs_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_branded_programs_updated_at
    BEFORE UPDATE ON branded_programs
    FOR EACH ROW
    EXECUTE FUNCTION update_branded_programs_timestamp();

-- Update timestamp trigger for user_program_assignments
CREATE OR REPLACE FUNCTION update_user_program_assignments_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_program_assignments_updated_at
    BEFORE UPDATE ON user_program_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_user_program_assignments_timestamp();

-- Log program assignments to user_context_logs
CREATE OR REPLACE FUNCTION log_program_assignment_change()
RETURNS TRIGGER AS $$
DECLARE
    program_name TEXT;
    event_type TEXT;
    event_data JSONB;
BEGIN
    -- Get program name
    IF NEW.branded_program_id IS NOT NULL THEN
        SELECT name INTO program_name FROM branded_programs WHERE id = NEW.branded_program_id;
    ELSE
        program_name := NEW.custom_program_name;
    END IF;

    -- Determine event type
    IF TG_OP = 'INSERT' THEN
        event_type := 'program_started';
        event_data := jsonb_build_object(
            'program_id', NEW.branded_program_id,
            'program_name', program_name,
            'custom_name', NEW.custom_program_name,
            'total_workouts', NEW.total_workouts,
            'assignment_id', NEW.id
        );
    ELSIF TG_OP = 'UPDATE' THEN
        -- Check what changed
        IF OLD.status != NEW.status THEN
            IF NEW.status = 'completed' THEN
                event_type := 'program_completed';
            ELSIF NEW.status = 'paused' THEN
                event_type := 'program_paused';
            ELSIF NEW.status = 'abandoned' THEN
                event_type := 'program_abandoned';
            ELSIF NEW.status = 'active' AND OLD.status = 'paused' THEN
                event_type := 'program_resumed';
            ELSE
                event_type := 'program_status_changed';
            END IF;
        ELSIF OLD.progress_percentage != NEW.progress_percentage OR
              OLD.workouts_completed != NEW.workouts_completed THEN
            event_type := 'program_progress_updated';
        ELSIF OLD.current_week != NEW.current_week THEN
            event_type := 'program_week_advanced';
        ELSE
            event_type := 'program_updated';
        END IF;

        event_data := jsonb_build_object(
            'program_id', NEW.branded_program_id,
            'program_name', program_name,
            'custom_name', NEW.custom_program_name,
            'progress_percentage', NEW.progress_percentage,
            'workouts_completed', NEW.workouts_completed,
            'current_week', NEW.current_week,
            'status', NEW.status,
            'assignment_id', NEW.id,
            'previous_status', OLD.status,
            'previous_progress', OLD.progress_percentage
        );
    END IF;

    -- Insert into user_context_logs if the table exists
    BEGIN
        INSERT INTO user_context_logs (user_id, event_type, event_data, created_at)
        VALUES (NEW.user_id, event_type, event_data, NOW());
    EXCEPTION WHEN undefined_table THEN
        -- Table doesn't exist, skip logging
        NULL;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_program_assignment
    AFTER INSERT OR UPDATE ON user_program_assignments
    FOR EACH ROW
    EXECUTE FUNCTION log_program_assignment_change();

-- ============================================================================
-- SEED DATA - BRANDED PROGRAMS
-- ============================================================================

INSERT INTO branded_programs (
    name, tagline, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type, goals,
    icon_name, color_hex, is_featured, is_premium, requires_gym, minimum_equipment
) VALUES

-- 1. Ultimate Strength
(
    'Ultimate Strength',
    'Build raw power and unbreakable strength',
    'A comprehensive 12-week program designed to maximize your strength gains through progressive overload, compound movements, and strategic periodization. Perfect for those who want to lift heavier and feel stronger in every aspect of life.',
    'strength',
    'advanced',
    12,
    4,
    'upper_lower',
    ARRAY['increase_strength', 'build_muscle', 'improve_power', 'enhance_performance'],
    'fitness_center',
    '#E63946',
    true,
    true,
    true,
    ARRAY['barbell', 'squat_rack', 'bench', 'dumbbells']
),

-- 2. Lean Machine
(
    'Lean Machine',
    'Sculpt your body, reveal your muscle',
    'An 8-week fat-burning program that combines high-intensity training with strategic muscle preservation. Get lean without losing your hard-earned muscle through smart nutrition timing and metabolic conditioning.',
    'fat_loss',
    'intermediate',
    8,
    5,
    'push_pull_legs',
    ARRAY['lose_fat', 'maintain_muscle', 'improve_conditioning', 'boost_metabolism'],
    'local_fire_department',
    '#FF6B35',
    true,
    false,
    true,
    ARRAY['dumbbells', 'cable_machine', 'cardio_equipment']
),

-- 3. Power Builder
(
    'Power Builder',
    'The best of both worlds: strength meets size',
    'An 8-week hybrid program combining powerlifting and bodybuilding principles. Build impressive strength while developing aesthetic muscle mass through strategic exercise selection and rep schemes.',
    'powerbuilding',
    'intermediate',
    8,
    5,
    'upper_lower',
    ARRAY['build_muscle', 'increase_strength', 'improve_aesthetics', 'enhance_power'],
    'flash_on',
    '#7B2CBF',
    true,
    true,
    true,
    ARRAY['barbell', 'squat_rack', 'bench', 'dumbbells', 'cable_machine']
),

-- 4. Beach Body Ready
(
    'Beach Body Ready',
    'Look good, feel confident',
    'A 12-week aesthetic-focused program designed to build a balanced, proportional physique. Emphasis on muscle definition, shoulder width, and core development for that classic V-taper look.',
    'hypertrophy',
    'intermediate',
    12,
    5,
    'push_pull_legs',
    ARRAY['build_muscle', 'improve_aesthetics', 'enhance_definition', 'boost_confidence'],
    'beach_access',
    '#00B4D8',
    true,
    true,
    true,
    ARRAY['dumbbells', 'cable_machine', 'machines']
),

-- 5. Functional Athlete
(
    'Functional Athlete',
    'Train like an athlete, move like one',
    'An 8-week athletic performance program that improves your functional strength, power, agility, and conditioning. Perfect for sports enthusiasts and anyone who wants to move better in daily life.',
    'athletic',
    'intermediate',
    8,
    4,
    'full_body',
    ARRAY['improve_performance', 'increase_power', 'enhance_agility', 'boost_conditioning'],
    'sports_soccer',
    '#2EC4B6',
    true,
    false,
    true,
    ARRAY['barbell', 'kettlebells', 'medicine_ball', 'plyometric_box']
),

-- 6. Beginner's Journey
(
    'Beginner''s Journey',
    'Your first step to a stronger you',
    'A 4-week introductory program designed specifically for fitness newcomers. Learn proper form, build foundational strength, and develop healthy exercise habits that will last a lifetime.',
    'general_fitness',
    'beginner',
    4,
    3,
    'full_body',
    ARRAY['learn_basics', 'build_foundation', 'develop_habits', 'gain_confidence'],
    'emoji_people',
    '#06D6A0',
    true,
    false,
    false,
    ARRAY['dumbbells', 'bodyweight']
),

-- 7. Home Warrior
(
    'Home Warrior',
    'No gym? No problem.',
    'A comprehensive bodyweight and minimal equipment program for those who train at home. Build strength, muscle, and endurance with creative exercises that require little to no equipment.',
    'bodyweight',
    'all_levels',
    8,
    4,
    'full_body',
    ARRAY['build_muscle', 'improve_strength', 'enhance_mobility', 'convenience'],
    'home',
    '#8338EC',
    true,
    false,
    false,
    ARRAY['bodyweight', 'resistance_bands', 'pull_up_bar']
),

-- 8. Iron Will
(
    'Iron Will',
    'Forge an unbreakable physique',
    'A 16-week advanced muscle-building program for experienced lifters. Push past plateaus with advanced techniques, strategic periodization, and intensity methods that force adaptation.',
    'hypertrophy',
    'advanced',
    16,
    6,
    'push_pull_legs',
    ARRAY['maximize_muscle', 'break_plateaus', 'advanced_techniques', 'elite_physique'],
    'whatshot',
    '#1D3557',
    false,
    true,
    true,
    ARRAY['barbell', 'dumbbells', 'cable_machine', 'machines', 'squat_rack']
),

-- 9. Quick Fit
(
    'Quick Fit',
    'Maximum results, minimum time',
    'A 4-week time-efficient program for busy professionals. Get effective workouts done in 30-45 minutes with strategic exercise selection and minimal rest periods.',
    'general_fitness',
    'intermediate',
    4,
    4,
    'full_body',
    ARRAY['time_efficient', 'maintain_fitness', 'boost_energy', 'convenience'],
    'timer',
    '#F77F00',
    true,
    false,
    true,
    ARRAY['dumbbells', 'cable_machine']
),

-- 10. Endurance Engine
(
    'Endurance Engine',
    'Build stamina that never quits',
    'An 8-week program combining cardiovascular conditioning with strength training. Improve your aerobic capacity, muscular endurance, and overall stamina for better performance in all activities.',
    'endurance',
    'intermediate',
    8,
    5,
    'full_body',
    ARRAY['improve_endurance', 'boost_cardio', 'maintain_strength', 'increase_stamina'],
    'directions_run',
    '#3A86FF',
    false,
    false,
    true,
    ARRAY['cardio_equipment', 'dumbbells', 'kettlebells']
),

-- 11. Core Crusher
(
    'Core Crusher',
    'Build an unshakeable foundation',
    'A 6-week intensive program focused on developing core strength, stability, and definition. Perfect as a standalone program or complement to your main training.',
    'general_fitness',
    'intermediate',
    6,
    4,
    'custom',
    ARRAY['core_strength', 'improve_stability', 'enhance_posture', 'reduce_back_pain'],
    'accessibility_new',
    '#FB5607',
    false,
    false,
    false,
    ARRAY['bodyweight', 'stability_ball', 'resistance_bands']
),

-- 12. Strength Foundations
(
    'Strength Foundations',
    'Master the basics, build for life',
    'An 8-week program teaching the fundamental barbell movements with progressive loading. Perfect for those transitioning from beginner to intermediate training.',
    'strength',
    'beginner',
    8,
    3,
    'full_body',
    ARRAY['learn_lifts', 'build_strength', 'proper_form', 'foundation'],
    'school',
    '#457B9D',
    false,
    false,
    true,
    ARRAY['barbell', 'squat_rack', 'bench']
);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get active program for a user
CREATE OR REPLACE FUNCTION get_user_active_program(p_user_id UUID)
RETURNS TABLE (
    assignment_id UUID,
    program_id UUID,
    program_name TEXT,
    custom_name TEXT,
    tagline TEXT,
    category TEXT,
    difficulty_level TEXT,
    duration_weeks INTEGER,
    sessions_per_week INTEGER,
    split_type TEXT,
    progress_percentage INTEGER,
    workouts_completed INTEGER,
    total_workouts INTEGER,
    current_week INTEGER,
    started_at TIMESTAMP WITH TIME ZONE,
    icon_name TEXT,
    color_hex TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        upa.id AS assignment_id,
        bp.id AS program_id,
        bp.name AS program_name,
        upa.custom_program_name AS custom_name,
        bp.tagline,
        bp.category,
        bp.difficulty_level,
        bp.duration_weeks,
        bp.sessions_per_week,
        bp.split_type,
        upa.progress_percentage,
        upa.workouts_completed,
        upa.total_workouts,
        upa.current_week,
        upa.started_at,
        bp.icon_name,
        bp.color_hex
    FROM user_program_assignments upa
    LEFT JOIN branded_programs bp ON bp.id = upa.branded_program_id
    WHERE upa.user_id = p_user_id
      AND upa.is_active = true
      AND upa.status = 'active'
    ORDER BY upa.started_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recommended programs for a user based on their profile
CREATE OR REPLACE FUNCTION get_recommended_programs(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    program_id UUID,
    name TEXT,
    tagline TEXT,
    category TEXT,
    difficulty_level TEXT,
    duration_weeks INTEGER,
    sessions_per_week INTEGER,
    icon_name TEXT,
    color_hex TEXT,
    is_featured BOOLEAN,
    is_premium BOOLEAN,
    match_score INTEGER
) AS $$
DECLARE
    user_goal TEXT;
    user_experience TEXT;
    user_equipment TEXT[];
BEGIN
    -- Get user preferences (adjust based on your users table structure)
    SELECT
        COALESCE(fitness_goal, 'general_fitness'),
        COALESCE(experience_level, 'beginner'),
        COALESCE(available_equipment, ARRAY['bodyweight'])
    INTO user_goal, user_experience, user_equipment
    FROM users
    WHERE id = p_user_id;

    RETURN QUERY
    SELECT
        bp.id AS program_id,
        bp.name,
        bp.tagline,
        bp.category,
        bp.difficulty_level,
        bp.duration_weeks,
        bp.sessions_per_week,
        bp.icon_name,
        bp.color_hex,
        bp.is_featured,
        bp.is_premium,
        -- Calculate match score
        (
            CASE WHEN bp.category = user_goal THEN 30 ELSE 0 END +
            CASE WHEN bp.difficulty_level = user_experience THEN 25 ELSE 0 END +
            CASE WHEN bp.difficulty_level = 'all_levels' THEN 15 ELSE 0 END +
            CASE WHEN bp.is_featured THEN 10 ELSE 0 END +
            CASE WHEN NOT bp.requires_gym OR bp.minimum_equipment <@ user_equipment THEN 20 ELSE 0 END
        )::INTEGER AS match_score
    FROM branded_programs bp
    WHERE bp.is_active = true
      AND bp.id NOT IN (
          SELECT branded_program_id
          FROM user_program_assignments
          WHERE user_id = p_user_id
            AND status IN ('active', 'completed')
            AND branded_program_id IS NOT NULL
      )
    ORDER BY match_score DESC, is_featured DESC, name ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to start a new program
CREATE OR REPLACE FUNCTION start_branded_program(
    p_user_id UUID,
    p_program_id UUID,
    p_custom_name TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_assignment_id UUID;
    v_total_workouts INTEGER;
    v_target_end_date TIMESTAMP WITH TIME ZONE;
    v_duration_weeks INTEGER;
    v_sessions_per_week INTEGER;
BEGIN
    -- Get program details
    SELECT duration_weeks, sessions_per_week
    INTO v_duration_weeks, v_sessions_per_week
    FROM branded_programs
    WHERE id = p_program_id AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Program not found or inactive';
    END IF;

    -- Calculate total workouts and end date
    v_total_workouts := v_duration_weeks * v_sessions_per_week;
    v_target_end_date := NOW() + (v_duration_weeks || ' weeks')::INTERVAL;

    -- Deactivate any existing active programs
    UPDATE user_program_assignments
    SET is_active = false,
        status = 'abandoned',
        updated_at = NOW()
    WHERE user_id = p_user_id
      AND is_active = true;

    -- Create new assignment
    INSERT INTO user_program_assignments (
        user_id,
        branded_program_id,
        custom_program_name,
        started_at,
        target_end_date,
        total_workouts,
        is_active,
        status
    ) VALUES (
        p_user_id,
        p_program_id,
        p_custom_name,
        NOW(),
        v_target_end_date,
        v_total_workouts,
        true,
        'active'
    ) RETURNING id INTO v_assignment_id;

    RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update program progress
CREATE OR REPLACE FUNCTION update_program_progress(
    p_user_id UUID,
    p_workouts_to_add INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
    v_assignment_id UUID;
    v_total_workouts INTEGER;
    v_new_completed INTEGER;
    v_new_percentage INTEGER;
    v_duration_weeks INTEGER;
    v_sessions_per_week INTEGER;
    v_new_week INTEGER;
BEGIN
    -- Get active assignment
    SELECT
        upa.id,
        upa.total_workouts,
        upa.workouts_completed,
        bp.duration_weeks,
        bp.sessions_per_week
    INTO v_assignment_id, v_total_workouts, v_new_completed, v_duration_weeks, v_sessions_per_week
    FROM user_program_assignments upa
    LEFT JOIN branded_programs bp ON bp.id = upa.branded_program_id
    WHERE upa.user_id = p_user_id AND upa.is_active = true
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    -- Calculate new values
    v_new_completed := v_new_completed + p_workouts_to_add;
    v_new_percentage := LEAST(100, (v_new_completed * 100 / NULLIF(v_total_workouts, 0)));
    v_new_week := LEAST(v_duration_weeks, (v_new_completed / NULLIF(v_sessions_per_week, 0)) + 1);

    -- Update assignment
    UPDATE user_program_assignments
    SET
        workouts_completed = v_new_completed,
        progress_percentage = COALESCE(v_new_percentage, 0),
        current_week = COALESCE(v_new_week, 1),
        status = CASE
            WHEN v_new_completed >= v_total_workouts THEN 'completed'
            ELSE 'active'
        END,
        completed_at = CASE
            WHEN v_new_completed >= v_total_workouts THEN NOW()
            ELSE NULL
        END,
        updated_at = NOW()
    WHERE id = v_assignment_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_user_active_program(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_recommended_programs(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION start_branded_program(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_program_progress(UUID, INTEGER) TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE branded_programs IS 'Pre-designed workout programs with branding, theming, and structure';
COMMENT ON TABLE user_program_assignments IS 'Tracks user enrollment in workout programs and their progress';

COMMENT ON COLUMN branded_programs.name IS 'Unique display name for the program';
COMMENT ON COLUMN branded_programs.tagline IS 'Short motivational tagline for marketing';
COMMENT ON COLUMN branded_programs.category IS 'Primary focus category of the program';
COMMENT ON COLUMN branded_programs.split_type IS 'Training split methodology used in the program';
COMMENT ON COLUMN branded_programs.goals IS 'Array of target outcomes for the program';
COMMENT ON COLUMN branded_programs.icon_name IS 'Material icon name for UI display';
COMMENT ON COLUMN branded_programs.color_hex IS 'Theme color in hex format (#RRGGBB)';

COMMENT ON COLUMN user_program_assignments.custom_program_name IS 'User-defined name for their program instance';
COMMENT ON COLUMN user_program_assignments.progress_percentage IS 'Overall completion percentage (0-100)';
COMMENT ON COLUMN user_program_assignments.current_week IS 'Current training week in the program';
COMMENT ON COLUMN user_program_assignments.difficulty_adjustment IS 'User adjustment to program difficulty (-2 to +2)';

COMMENT ON FUNCTION get_user_active_program IS 'Returns the currently active program for a user';
COMMENT ON FUNCTION get_recommended_programs IS 'Returns personalized program recommendations based on user profile';
COMMENT ON FUNCTION start_branded_program IS 'Enrolls a user in a branded program, deactivating any existing active programs';
COMMENT ON FUNCTION update_program_progress IS 'Increments workout completion and recalculates progress metrics';
