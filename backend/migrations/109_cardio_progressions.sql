-- Migration 109: Cardio Progression Programs (Couch-to-5K style)
-- Implements gradual running/cardio progression with run/walk intervals
-- Includes strain detection, automatic pace adjustment, and age-aware progression
--
-- Key features:
-- 1. Multiple program types (couch_to_5k, walk_to_run, build_endurance, custom)
-- 2. Progression paces (very_slow for seniors, gradual, moderate, aggressive)
-- 3. Session tracking with strain reporting
-- 4. Automatic adjustments based on user feedback

-- ===================================
-- Table: cardio_progression_programs
-- ===================================
-- Stores user cardio progression programs (e.g., Couch-to-5K)
CREATE TABLE IF NOT EXISTS cardio_progression_programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Program configuration
    program_type TEXT NOT NULL CHECK (program_type IN ('couch_to_5k', 'walk_to_run', 'build_endurance', 'custom')),
    program_name TEXT,  -- Custom name for the program

    -- Progress tracking
    current_week INTEGER NOT NULL DEFAULT 1 CHECK (current_week >= 1),
    total_weeks INTEGER NOT NULL DEFAULT 8 CHECK (total_weeks >= 1 AND total_weeks <= 24),
    sessions_completed_this_week INTEGER NOT NULL DEFAULT 0,
    total_sessions_completed INTEGER NOT NULL DEFAULT 0,

    -- Timing
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    target_completion_date TIMESTAMPTZ,
    paused_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Status
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'abandoned')),

    -- Progression settings
    progression_pace TEXT NOT NULL DEFAULT 'gradual' CHECK (progression_pace IN ('very_slow', 'gradual', 'moderate', 'aggressive')),
    weekly_sessions INTEGER NOT NULL DEFAULT 3 CHECK (weekly_sessions >= 1 AND weekly_sessions <= 7),
    preferred_days TEXT[], -- e.g., ['monday', 'wednesday', 'friday']

    -- Current interval settings (in seconds for precision)
    current_run_duration_seconds INTEGER NOT NULL DEFAULT 60,
    current_walk_duration_seconds INTEGER NOT NULL DEFAULT 120,
    current_intervals_per_session INTEGER NOT NULL DEFAULT 4,

    -- Targets
    target_continuous_run_minutes INTEGER NOT NULL DEFAULT 30,
    target_distance_km DECIMAL(4,2),

    -- User context for adjustments
    user_age_at_start INTEGER,
    initial_fitness_level TEXT CHECK (initial_fitness_level IN ('sedentary', 'beginner', 'intermediate', 'advanced')),

    -- Strain/injury history
    total_strain_reports INTEGER NOT NULL DEFAULT 0,
    weeks_repeated INTEGER NOT NULL DEFAULT 0,

    -- Notes
    notes TEXT,
    ai_recommendations TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===================================
-- Table: cardio_progression_sessions
-- ===================================
-- Individual workout sessions within a program
CREATE TABLE IF NOT EXISTS cardio_progression_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id UUID NOT NULL REFERENCES cardio_progression_programs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Session position in program
    week_number INTEGER NOT NULL CHECK (week_number >= 1),
    session_number INTEGER NOT NULL CHECK (session_number >= 1 AND session_number <= 7),

    -- Scheduling
    planned_date DATE,
    completed_at TIMESTAMPTZ,
    skipped BOOLEAN DEFAULT FALSE,
    skipped_reason TEXT,

    -- Workout structure
    run_intervals INTEGER NOT NULL CHECK (run_intervals >= 1),
    run_duration_seconds INTEGER NOT NULL CHECK (run_duration_seconds >= 10),
    walk_duration_seconds INTEGER NOT NULL CHECK (walk_duration_seconds >= 0),
    total_duration_minutes INTEGER NOT NULL CHECK (total_duration_minutes >= 5),

    -- Actual performance
    actual_run_intervals_completed INTEGER,
    actual_total_duration_minutes INTEGER,
    actual_distance_km DECIMAL(5,2),

    -- Heart rate tracking
    average_heart_rate INTEGER CHECK (average_heart_rate IS NULL OR (average_heart_rate >= 40 AND average_heart_rate <= 220)),
    max_heart_rate INTEGER CHECK (max_heart_rate IS NULL OR (max_heart_rate >= 40 AND max_heart_rate <= 250)),
    hr_zone_time_zone1_minutes INTEGER, -- Recovery zone
    hr_zone_time_zone2_minutes INTEGER, -- Aerobic zone
    hr_zone_time_zone3_minutes INTEGER, -- Tempo zone

    -- Subjective feedback
    perceived_difficulty INTEGER CHECK (perceived_difficulty IS NULL OR (perceived_difficulty >= 1 AND perceived_difficulty <= 10)),
    perceived_effort_rpe INTEGER CHECK (perceived_effort_rpe IS NULL OR (perceived_effort_rpe >= 1 AND perceived_effort_rpe <= 10)),
    enjoyment_rating INTEGER CHECK (enjoyment_rating IS NULL OR (enjoyment_rating >= 1 AND enjoyment_rating <= 5)),

    -- Strain/injury reporting
    strain_reported BOOLEAN DEFAULT FALSE,
    strain_location TEXT,
    strain_severity INTEGER CHECK (strain_severity IS NULL OR (strain_severity >= 1 AND strain_severity <= 5)),

    -- Environmental factors
    weather_conditions TEXT,
    terrain_type TEXT CHECK (terrain_type IS NULL OR terrain_type IN ('treadmill', 'track', 'road', 'trail', 'grass', 'mixed')),

    -- Notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===================================
-- Table: cardio_progression_templates
-- ===================================
-- Stores progression templates (weekly structures)
CREATE TABLE IF NOT EXISTS cardio_progression_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Template info
    pace_type TEXT NOT NULL CHECK (pace_type IN ('very_slow', 'gradual', 'moderate', 'aggressive')),
    week_number INTEGER NOT NULL CHECK (week_number >= 1 AND week_number <= 24),

    -- Interval structure
    run_duration_seconds INTEGER NOT NULL,
    walk_duration_seconds INTEGER NOT NULL,
    intervals INTEGER NOT NULL,
    total_duration_minutes INTEGER NOT NULL,

    -- Description
    description TEXT NOT NULL,
    coaching_tips TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ===================================
-- Indexes for Performance
-- ===================================
CREATE INDEX IF NOT EXISTS idx_cardio_prog_user_status ON cardio_progression_programs(user_id, status);
CREATE INDEX IF NOT EXISTS idx_cardio_prog_user_active ON cardio_progression_programs(user_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_cardio_prog_started ON cardio_progression_programs(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_cardio_sess_program ON cardio_progression_sessions(program_id, week_number);
CREATE INDEX IF NOT EXISTS idx_cardio_sess_user ON cardio_progression_sessions(user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_cardio_sess_planned ON cardio_progression_sessions(user_id, planned_date) WHERE completed_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_cardio_sess_strain ON cardio_progression_sessions(user_id) WHERE strain_reported = TRUE;

CREATE INDEX IF NOT EXISTS idx_cardio_template_pace_week ON cardio_progression_templates(pace_type, week_number);

-- ===================================
-- Trigger: Auto-update updated_at
-- ===================================
CREATE OR REPLACE FUNCTION update_cardio_prog_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cardio_prog_updated_at ON cardio_progression_programs;
CREATE TRIGGER trigger_cardio_prog_updated_at
    BEFORE UPDATE ON cardio_progression_programs
    FOR EACH ROW
    EXECUTE FUNCTION update_cardio_prog_updated_at();

-- ===================================
-- Row Level Security (RLS)
-- ===================================
ALTER TABLE cardio_progression_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cardio_progression_sessions ENABLE ROW LEVEL SECURITY;

-- Programs RLS
DROP POLICY IF EXISTS "Users can view own cardio programs" ON cardio_progression_programs;
CREATE POLICY "Users can view own cardio programs"
    ON cardio_progression_programs FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own cardio programs" ON cardio_progression_programs;
CREATE POLICY "Users can insert own cardio programs"
    ON cardio_progression_programs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own cardio programs" ON cardio_progression_programs;
CREATE POLICY "Users can update own cardio programs"
    ON cardio_progression_programs FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own cardio programs" ON cardio_progression_programs;
CREATE POLICY "Users can delete own cardio programs"
    ON cardio_progression_programs FOR DELETE
    USING (auth.uid() = user_id);

-- Sessions RLS
DROP POLICY IF EXISTS "Users can view own cardio sessions" ON cardio_progression_sessions;
CREATE POLICY "Users can view own cardio sessions"
    ON cardio_progression_sessions FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own cardio sessions" ON cardio_progression_sessions;
CREATE POLICY "Users can insert own cardio sessions"
    ON cardio_progression_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own cardio sessions" ON cardio_progression_sessions;
CREATE POLICY "Users can update own cardio sessions"
    ON cardio_progression_sessions FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own cardio sessions" ON cardio_progression_sessions;
CREATE POLICY "Users can delete own cardio sessions"
    ON cardio_progression_sessions FOR DELETE
    USING (auth.uid() = user_id);

-- Templates are read-only for all authenticated users
DROP POLICY IF EXISTS "Authenticated users can view templates" ON cardio_progression_templates;
CREATE POLICY "Authenticated users can view templates"
    ON cardio_progression_templates FOR SELECT
    TO authenticated
    USING (true);

-- ===================================
-- Seed Data: Progression Templates
-- ===================================

-- VERY_SLOW progression (12 weeks) - ideal for seniors/true beginners
INSERT INTO cardio_progression_templates (pace_type, week_number, run_duration_seconds, walk_duration_seconds, intervals, total_duration_minutes, description, coaching_tips)
VALUES
    ('very_slow', 1, 15, 120, 4, 15, '15s jog, 2min walk x4', 'Focus on gentle movement. Walking is the main activity.'),
    ('very_slow', 2, 20, 120, 4, 15, '20s jog, 2min walk x4', 'Still primarily walking. Keep the jog very light.'),
    ('very_slow', 3, 30, 120, 5, 18, '30s jog, 2min walk x5', 'Slight increase in jog time. Stay comfortable.'),
    ('very_slow', 4, 45, 120, 5, 20, '45s jog, 2min walk x5', 'Building confidence with longer jogs.'),
    ('very_slow', 5, 60, 120, 5, 22, '1min jog, 2min walk x5', 'One minute of jogging is a milestone!'),
    ('very_slow', 6, 90, 120, 4, 22, '90s jog, 2min walk x4', 'Fewer intervals but longer jog periods.'),
    ('very_slow', 7, 120, 90, 5, 25, '2min jog, 90s walk x5', 'Two-minute jogs with slightly less walk time.'),
    ('very_slow', 8, 180, 90, 4, 26, '3min jog, 90s walk x4', 'Three minutes of continuous jogging.'),
    ('very_slow', 9, 240, 60, 4, 28, '4min jog, 1min walk x4', 'Four-minute jogs with short recovery walks.'),
    ('very_slow', 10, 300, 60, 4, 30, '5min jog, 1min walk x4', 'Five-minute jogs! You are building real endurance.'),
    ('very_slow', 11, 480, 60, 3, 30, '8min jog, 1min walk x3', 'Longer continuous jogs with brief walk breaks.'),
    ('very_slow', 12, 900, 0, 2, 30, '15min continuous x2', 'Two 15-minute continuous jogs with rest between.')
ON CONFLICT DO NOTHING;

-- GRADUAL progression (9 weeks) - standard Couch to 5K
INSERT INTO cardio_progression_templates (pace_type, week_number, run_duration_seconds, walk_duration_seconds, intervals, total_duration_minutes, description, coaching_tips)
VALUES
    ('gradual', 1, 60, 90, 8, 20, '1min run, 90s walk x8', 'Start with short run intervals. Focus on breathing.'),
    ('gradual', 2, 90, 120, 6, 21, '90s run, 2min walk x6', 'Slightly longer runs with generous recovery.'),
    ('gradual', 3, 120, 120, 5, 20, '2min run, 2min walk x5', 'Equal run and walk periods.'),
    ('gradual', 4, 180, 90, 5, 22, '3min run, 90s walk x5', 'Three-minute runs with shorter recoveries.'),
    ('gradual', 5, 300, 60, 4, 24, '5min run, 1min walk x4', 'Five-minute runs! You can do this.'),
    ('gradual', 6, 480, 60, 3, 27, '8min run, 1min walk x3', 'Eight-minute runs. You are becoming a runner.'),
    ('gradual', 7, 720, 60, 2, 26, '12min run, 1min walk x2', 'Twelve-minute runs with brief walk breaks.'),
    ('gradual', 8, 1200, 0, 1, 20, '20min continuous', 'Twenty minutes of continuous running!'),
    ('gradual', 9, 1800, 0, 1, 30, '30min continuous (5K!)', 'Congratulations! You can run a 5K!')
ON CONFLICT DO NOTHING;

-- MODERATE progression (6 weeks) - for those with some base fitness
INSERT INTO cardio_progression_templates (pace_type, week_number, run_duration_seconds, walk_duration_seconds, intervals, total_duration_minutes, description, coaching_tips)
VALUES
    ('moderate', 1, 120, 60, 6, 18, '2min run, 1min walk x6', 'Start with two-minute runs.'),
    ('moderate', 2, 240, 60, 4, 20, '4min run, 1min walk x4', 'Four-minute runs. Find your rhythm.'),
    ('moderate', 3, 420, 60, 3, 24, '7min run, 1min walk x3', 'Seven-minute runs. Stay steady.'),
    ('moderate', 4, 600, 60, 2, 22, '10min run, 1min walk x2', 'Ten-minute runs. Strong progress!'),
    ('moderate', 5, 900, 0, 2, 30, '15min run x2', 'Two 15-minute runs with rest between.'),
    ('moderate', 6, 1800, 0, 1, 30, '30min continuous', 'Full 30 minutes. You made it!')
ON CONFLICT DO NOTHING;

-- AGGRESSIVE progression (4 weeks) - for athletic individuals
INSERT INTO cardio_progression_templates (pace_type, week_number, run_duration_seconds, walk_duration_seconds, intervals, total_duration_minutes, description, coaching_tips)
VALUES
    ('aggressive', 1, 300, 60, 4, 24, '5min run, 1min walk x4', 'Five-minute runs to start.'),
    ('aggressive', 2, 600, 60, 2, 22, '10min run, 1min walk x2', 'Ten-minute runs with brief recovery.'),
    ('aggressive', 3, 900, 0, 2, 30, '15min run x2', 'Two 15-minute continuous runs.'),
    ('aggressive', 4, 1800, 0, 1, 30, '30min continuous', 'Full 30 minutes non-stop!')
ON CONFLICT DO NOTHING;

-- ===================================
-- View: Active Cardio Programs
-- ===================================
CREATE OR REPLACE VIEW active_cardio_programs AS
SELECT
    cpp.id,
    cpp.user_id,
    cpp.program_type,
    cpp.program_name,
    cpp.current_week,
    cpp.total_weeks,
    cpp.status,
    cpp.progression_pace,
    cpp.weekly_sessions,
    cpp.sessions_completed_this_week,
    cpp.total_sessions_completed,
    cpp.current_run_duration_seconds,
    cpp.current_walk_duration_seconds,
    cpp.current_intervals_per_session,
    cpp.target_continuous_run_minutes,
    cpp.total_strain_reports,
    cpp.weeks_repeated,
    cpp.started_at,
    cpp.updated_at,
    ROUND((cpp.current_week::DECIMAL / cpp.total_weeks) * 100, 1) as progress_percent,
    (cpp.total_weeks - cpp.current_week) as weeks_remaining
FROM cardio_progression_programs cpp
WHERE cpp.status = 'active';

GRANT SELECT ON active_cardio_programs TO authenticated;

-- ===================================
-- View: Recent Cardio Sessions
-- ===================================
CREATE OR REPLACE VIEW recent_cardio_sessions AS
SELECT
    cps.id,
    cps.user_id,
    cps.program_id,
    cps.week_number,
    cps.session_number,
    cps.run_intervals,
    cps.run_duration_seconds,
    cps.walk_duration_seconds,
    cps.total_duration_minutes,
    cps.perceived_difficulty,
    cps.strain_reported,
    cps.strain_location,
    cps.completed_at,
    cps.actual_distance_km,
    cpp.program_type,
    cpp.progression_pace
FROM cardio_progression_sessions cps
JOIN cardio_progression_programs cpp ON cps.program_id = cpp.id
WHERE cps.completed_at IS NOT NULL
ORDER BY cps.completed_at DESC;

GRANT SELECT ON recent_cardio_sessions TO authenticated;

-- ===================================
-- Comments for Documentation
-- ===================================
COMMENT ON TABLE cardio_progression_programs IS 'Stores user cardio progression programs like Couch-to-5K with gradual run/walk intervals';
COMMENT ON TABLE cardio_progression_sessions IS 'Individual workout sessions within a cardio progression program';
COMMENT ON TABLE cardio_progression_templates IS 'Pre-defined progression templates for different paces (very_slow, gradual, moderate, aggressive)';

COMMENT ON COLUMN cardio_progression_programs.progression_pace IS 'Pace of progression: very_slow (12 weeks, seniors), gradual (9 weeks, standard C25K), moderate (6 weeks), aggressive (4 weeks)';
COMMENT ON COLUMN cardio_progression_sessions.strain_reported IS 'Whether user reported any strain during this session - triggers automatic program adjustment';
COMMENT ON COLUMN cardio_progression_sessions.perceived_difficulty IS 'RPE-style difficulty rating 1-10. 8+ triggers automatic slowdown recommendations';
COMMENT ON COLUMN cardio_progression_sessions.strain_severity IS 'Strain severity 1-5: 1=mild discomfort, 3=notable pain, 5=severe (stop immediately)';

COMMENT ON VIEW active_cardio_programs IS 'View of all active cardio progression programs with calculated progress percentage';
COMMENT ON VIEW recent_cardio_sessions IS 'View of recently completed cardio sessions with program context';
