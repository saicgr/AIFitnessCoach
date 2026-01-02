-- Migration: 089_leverage_progressions.sql
-- Description: Leverage-based exercise progressions integrated with regular workout generation
-- Date: 2025-12-30
-- Purpose: Track user exercise mastery, progression chains, and rep range preferences
--          to enable automatic exercise difficulty progression based on feedback

-- ============================================
-- TABLE: exercise_variant_chains
-- Defines progression chains for common exercises
-- ============================================

CREATE TABLE IF NOT EXISTS exercise_variant_chains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    base_exercise_name VARCHAR(100) NOT NULL,
    muscle_group VARCHAR(50) NOT NULL,
    chain_type VARCHAR(30) NOT NULL CHECK (chain_type IN ('leverage', 'load', 'tempo', 'range_of_motion')),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(base_exercise_name, chain_type)
);

-- Ensure unique constraint exists (may not exist if table was created partially)
CREATE UNIQUE INDEX IF NOT EXISTS idx_exercise_variant_chains_unique
    ON exercise_variant_chains(base_exercise_name, chain_type);

COMMENT ON TABLE exercise_variant_chains IS 'Defines progression chains for common exercises grouped by base movement';
COMMENT ON COLUMN exercise_variant_chains.base_exercise_name IS 'The foundational exercise name (e.g., Push-up, Pull-up, Squat)';
COMMENT ON COLUMN exercise_variant_chains.muscle_group IS 'Primary muscle group targeted (chest, back, legs, shoulders, arms, core)';
COMMENT ON COLUMN exercise_variant_chains.chain_type IS 'Progression type: leverage (body position), load (weight), tempo (speed), range_of_motion';

-- ============================================
-- TABLE: exercise_variants
-- Individual variants within each progression chain
-- ============================================

CREATE TABLE IF NOT EXISTS exercise_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chain_id UUID NOT NULL REFERENCES exercise_variant_chains(id) ON DELETE CASCADE,
    exercise_name VARCHAR(200) NOT NULL,
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 10),
    step_order INTEGER NOT NULL,
    unlock_criteria JSONB NOT NULL DEFAULT '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 2}',
    prerequisites TEXT[] DEFAULT ARRAY[]::TEXT[],
    equipment_required TEXT[] DEFAULT ARRAY[]::TEXT[],
    notes TEXT,
    form_cues TEXT[],
    video_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chain_id, step_order),
    UNIQUE(chain_id, exercise_name)
);

-- Ensure unique constraints exist for exercise_variants (may not exist if table was created partially)
CREATE UNIQUE INDEX IF NOT EXISTS idx_exercise_variants_chain_step_unique
    ON exercise_variants(chain_id, step_order);
CREATE UNIQUE INDEX IF NOT EXISTS idx_exercise_variants_chain_name_unique
    ON exercise_variants(chain_id, exercise_name);

COMMENT ON TABLE exercise_variants IS 'Individual exercise variants within a progression chain ordered by difficulty';
COMMENT ON COLUMN exercise_variants.exercise_name IS 'Specific exercise variant name (e.g., Archer Push-up)';
COMMENT ON COLUMN exercise_variants.difficulty_level IS 'Difficulty rating from 1 (easiest) to 10 (hardest)';
COMMENT ON COLUMN exercise_variants.step_order IS 'Order in the progression chain (1 = first/easiest)';
COMMENT ON COLUMN exercise_variants.unlock_criteria IS 'JSONB criteria: min_reps, min_sets, consecutive_sessions, hold_seconds, etc.';
COMMENT ON COLUMN exercise_variants.prerequisites IS 'Array of exercise names that must be mastered first';
COMMENT ON COLUMN exercise_variants.equipment_required IS 'Array of required equipment (empty for bodyweight)';
COMMENT ON COLUMN exercise_variants.form_cues IS 'Array of form tips and cues for proper execution';

-- ============================================
-- TABLE: user_exercise_mastery
-- Track user's mastery level for each exercise
-- ============================================

CREATE TABLE IF NOT EXISTS user_exercise_mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_name VARCHAR(200) NOT NULL,
    chain_id UUID REFERENCES exercise_variant_chains(id) ON DELETE SET NULL,
    current_max_reps INTEGER DEFAULT 0,
    current_max_weight DECIMAL(7,2) DEFAULT 0,
    current_max_hold_seconds INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    total_sets_completed INTEGER DEFAULT 0,
    consecutive_easy_sessions INTEGER DEFAULT 0,
    consecutive_hard_sessions INTEGER DEFAULT 0,
    ready_for_progression BOOLEAN DEFAULT FALSE,
    suggested_next_variant VARCHAR(200),
    last_feedback VARCHAR(20) CHECK (last_feedback IN ('too_easy', 'just_right', 'too_hard')),
    last_performed_at TIMESTAMP WITH TIME ZONE,
    first_performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, exercise_name)
);

-- Ensure all columns exist if table was created in an earlier migration without them
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS exercise_name VARCHAR(200);
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS chain_id UUID;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS current_max_reps INTEGER DEFAULT 0;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS current_max_weight DECIMAL(7,2) DEFAULT 0;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS current_max_hold_seconds INTEGER DEFAULT 0;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS total_sessions INTEGER DEFAULT 0;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS total_sets_completed INTEGER DEFAULT 0;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS consecutive_easy_sessions INTEGER DEFAULT 0;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS consecutive_hard_sessions INTEGER DEFAULT 0;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS ready_for_progression BOOLEAN DEFAULT FALSE;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS suggested_next_variant VARCHAR(200);
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS last_feedback VARCHAR(20);
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS last_performed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS first_performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE user_exercise_mastery ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

COMMENT ON TABLE user_exercise_mastery IS 'Tracks user mastery progress for each exercise performed';
COMMENT ON COLUMN user_exercise_mastery.current_max_reps IS 'Best reps achieved in a single set';
COMMENT ON COLUMN user_exercise_mastery.current_max_weight IS 'Maximum weight used (in kg)';
COMMENT ON COLUMN user_exercise_mastery.current_max_hold_seconds IS 'Maximum hold time for isometric exercises';
COMMENT ON COLUMN user_exercise_mastery.consecutive_easy_sessions IS 'Count of consecutive "too easy" feedback sessions';
COMMENT ON COLUMN user_exercise_mastery.consecutive_hard_sessions IS 'Count of consecutive "too hard" feedback sessions';
COMMENT ON COLUMN user_exercise_mastery.ready_for_progression IS 'True when user meets unlock criteria for next variant';
COMMENT ON COLUMN user_exercise_mastery.suggested_next_variant IS 'Name of the suggested progression exercise';

-- ============================================
-- TABLE: user_rep_range_preferences
-- User preferences for training style and rep ranges
-- ============================================

CREATE TABLE IF NOT EXISTS user_rep_range_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    training_focus VARCHAR(30) NOT NULL DEFAULT 'hypertrophy' CHECK (
        training_focus IN ('strength', 'hypertrophy', 'endurance', 'power', 'balanced')
    ),
    preferred_min_reps INTEGER NOT NULL DEFAULT 8,
    preferred_max_reps INTEGER NOT NULL DEFAULT 12,
    avoid_high_reps BOOLEAN DEFAULT FALSE,
    max_reps_ceiling INTEGER DEFAULT 20,
    progression_style VARCHAR(30) NOT NULL DEFAULT 'balanced' CHECK (
        progression_style IN ('leverage_first', 'load_first', 'balanced', 'technique_first')
    ),
    auto_progression_enabled BOOLEAN DEFAULT TRUE,
    progression_sensitivity VARCHAR(20) DEFAULT 'normal' CHECK (
        progression_sensitivity IN ('conservative', 'normal', 'aggressive')
    ),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure all columns exist if table was created partially in a previous migration
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS training_focus VARCHAR(30) DEFAULT 'hypertrophy';
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS preferred_min_reps INTEGER DEFAULT 8;
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS preferred_max_reps INTEGER DEFAULT 12;
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS avoid_high_reps BOOLEAN DEFAULT FALSE;
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS max_reps_ceiling INTEGER DEFAULT 20;
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS progression_style VARCHAR(30) DEFAULT 'balanced';
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS auto_progression_enabled BOOLEAN DEFAULT TRUE;
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS progression_sensitivity VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE user_rep_range_preferences ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

COMMENT ON TABLE user_rep_range_preferences IS 'Stores user preferences for training style and automatic progression';
COMMENT ON COLUMN user_rep_range_preferences.training_focus IS 'Primary training goal: strength (1-5 reps), hypertrophy (8-12), endurance (15+), power (explosive), balanced';
COMMENT ON COLUMN user_rep_range_preferences.preferred_min_reps IS 'Minimum reps per set based on training focus';
COMMENT ON COLUMN user_rep_range_preferences.preferred_max_reps IS 'Maximum reps per set based on training focus';
COMMENT ON COLUMN user_rep_range_preferences.avoid_high_reps IS 'When true, prevents prescribing 15+ rep sets';
COMMENT ON COLUMN user_rep_range_preferences.max_reps_ceiling IS 'Absolute maximum reps to ever prescribe (even for endurance)';
COMMENT ON COLUMN user_rep_range_preferences.progression_style IS 'How to progress: leverage changes, load increases, or balanced approach';
COMMENT ON COLUMN user_rep_range_preferences.auto_progression_enabled IS 'Whether to automatically suggest progressions';
COMMENT ON COLUMN user_rep_range_preferences.progression_sensitivity IS 'How quickly to suggest progressions based on feedback';

-- ============================================
-- TABLE: progression_history
-- Track progression events for analytics
-- ============================================

CREATE TABLE IF NOT EXISTS progression_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_exercise VARCHAR(200) NOT NULL,
    to_exercise VARCHAR(200) NOT NULL,
    chain_id UUID REFERENCES exercise_variant_chains(id) ON DELETE SET NULL,
    progression_type VARCHAR(30) NOT NULL CHECK (
        progression_type IN ('leverage_upgrade', 'load_increase', 'regression', 'lateral_move')
    ),
    trigger_reason VARCHAR(50) NOT NULL CHECK (
        trigger_reason IN ('too_easy_feedback', 'criteria_met', 'manual_selection', 'ai_suggestion', 'regression_needed')
    ),
    from_stats JSONB DEFAULT '{}',
    to_initial_stats JSONB DEFAULT '{}',
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure all columns exist if table was created partially in a previous migration
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS from_exercise VARCHAR(200);
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS to_exercise VARCHAR(200);
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS chain_id UUID;
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS progression_type VARCHAR(30);
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS trigger_reason VARCHAR(50);
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS from_stats JSONB DEFAULT '{}';
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS to_initial_stats JSONB DEFAULT '{}';
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS workout_id UUID;
ALTER TABLE progression_history ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

COMMENT ON TABLE progression_history IS 'Audit trail of exercise progressions and regressions';
COMMENT ON COLUMN progression_history.from_exercise IS 'Exercise being replaced or progressed from';
COMMENT ON COLUMN progression_history.to_exercise IS 'New exercise being progressed to';
COMMENT ON COLUMN progression_history.progression_type IS 'Type of change: upgrade, load increase, regression, or lateral';
COMMENT ON COLUMN progression_history.trigger_reason IS 'What triggered this progression';
COMMENT ON COLUMN progression_history.from_stats IS 'User stats at time of progression (max_reps, sets, etc.)';
COMMENT ON COLUMN progression_history.to_initial_stats IS 'Starting stats for the new exercise';

-- ============================================
-- INDEXES
-- ============================================

-- exercise_variant_chains indexes
CREATE INDEX IF NOT EXISTS idx_variant_chains_base_name ON exercise_variant_chains(base_exercise_name);
CREATE INDEX IF NOT EXISTS idx_variant_chains_muscle_group ON exercise_variant_chains(muscle_group);
CREATE INDEX IF NOT EXISTS idx_variant_chains_type ON exercise_variant_chains(chain_type);

-- exercise_variants indexes
CREATE INDEX IF NOT EXISTS idx_variants_chain_id ON exercise_variants(chain_id);
CREATE INDEX IF NOT EXISTS idx_variants_exercise_name ON exercise_variants(exercise_name);
CREATE INDEX IF NOT EXISTS idx_variants_difficulty ON exercise_variants(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_variants_chain_order ON exercise_variants(chain_id, step_order);

-- user_exercise_mastery indexes
CREATE INDEX IF NOT EXISTS idx_user_mastery_user_id ON user_exercise_mastery(user_id);
CREATE INDEX IF NOT EXISTS idx_user_mastery_exercise ON user_exercise_mastery(exercise_name);
CREATE INDEX IF NOT EXISTS idx_user_mastery_user_exercise ON user_exercise_mastery(user_id, exercise_name);
CREATE INDEX IF NOT EXISTS idx_user_mastery_chain ON user_exercise_mastery(chain_id) WHERE chain_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_mastery_ready ON user_exercise_mastery(user_id, ready_for_progression) WHERE ready_for_progression = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_mastery_last_performed ON user_exercise_mastery(user_id, last_performed_at DESC);

-- user_rep_range_preferences indexes
CREATE INDEX IF NOT EXISTS idx_rep_prefs_user_id ON user_rep_range_preferences(user_id);

-- progression_history indexes
CREATE INDEX IF NOT EXISTS idx_progression_history_user ON progression_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_progression_history_chain ON progression_history(chain_id) WHERE chain_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_progression_history_workout ON progression_history(workout_id) WHERE workout_id IS NOT NULL;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE exercise_variant_chains ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_exercise_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_rep_range_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE progression_history ENABLE ROW LEVEL SECURITY;

-- exercise_variant_chains: Public read access (reference data)
DROP POLICY IF EXISTS "Anyone can read variant chains" ON exercise_variant_chains;
CREATE POLICY "Anyone can read variant chains" ON exercise_variant_chains
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Service role manages variant chains" ON exercise_variant_chains;
CREATE POLICY "Service role manages variant chains" ON exercise_variant_chains
    FOR ALL USING (auth.role() = 'service_role');

-- exercise_variants: Public read access (reference data)
DROP POLICY IF EXISTS "Anyone can read variants" ON exercise_variants;
CREATE POLICY "Anyone can read variants" ON exercise_variants
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Service role manages variants" ON exercise_variants;
CREATE POLICY "Service role manages variants" ON exercise_variants
    FOR ALL USING (auth.role() = 'service_role');

-- user_exercise_mastery: User-scoped access
DROP POLICY IF EXISTS "Users can view own mastery" ON user_exercise_mastery;
CREATE POLICY "Users can view own mastery" ON user_exercise_mastery
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own mastery" ON user_exercise_mastery;
CREATE POLICY "Users can insert own mastery" ON user_exercise_mastery
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own mastery" ON user_exercise_mastery;
CREATE POLICY "Users can update own mastery" ON user_exercise_mastery
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own mastery" ON user_exercise_mastery;
CREATE POLICY "Users can delete own mastery" ON user_exercise_mastery
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role manages mastery" ON user_exercise_mastery;
CREATE POLICY "Service role manages mastery" ON user_exercise_mastery
    FOR ALL USING (auth.role() = 'service_role');

-- user_rep_range_preferences: User-scoped access
DROP POLICY IF EXISTS "Users can view own rep preferences" ON user_rep_range_preferences;
CREATE POLICY "Users can view own rep preferences" ON user_rep_range_preferences
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own rep preferences" ON user_rep_range_preferences;
CREATE POLICY "Users can insert own rep preferences" ON user_rep_range_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own rep preferences" ON user_rep_range_preferences;
CREATE POLICY "Users can update own rep preferences" ON user_rep_range_preferences
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own rep preferences" ON user_rep_range_preferences;
CREATE POLICY "Users can delete own rep preferences" ON user_rep_range_preferences
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role manages rep preferences" ON user_rep_range_preferences;
CREATE POLICY "Service role manages rep preferences" ON user_rep_range_preferences
    FOR ALL USING (auth.role() = 'service_role');

-- progression_history: User-scoped access
DROP POLICY IF EXISTS "Users can view own progression history" ON progression_history;
CREATE POLICY "Users can view own progression history" ON progression_history
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own progression history" ON progression_history;
CREATE POLICY "Users can insert own progression history" ON progression_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role manages progression history" ON progression_history;
CREATE POLICY "Service role manages progression history" ON progression_history
    FOR ALL USING (auth.role() = 'service_role');

-- ============================================
-- TRIGGER: Update updated_at timestamp
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_user_exercise_mastery_updated_at ON user_exercise_mastery;
CREATE TRIGGER trigger_user_exercise_mastery_updated_at
    BEFORE UPDATE ON user_exercise_mastery
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_user_rep_range_preferences_updated_at ON user_rep_range_preferences;
CREATE TRIGGER trigger_user_rep_range_preferences_updated_at
    BEFORE UPDATE ON user_rep_range_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA: Exercise Variant Chains
-- ============================================

-- Push-up progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a1111111-1111-1111-1111-111111111111', 'Push-up', 'chest', 'leverage',
     'Progress through push-up variations by changing body angle and limb positioning to increase difficulty through leverage changes.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- Pull-up progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a2222222-2222-2222-2222-222222222222', 'Pull-up', 'back', 'leverage',
     'Master pulling movements from basic hangs to one-arm pulls through progressive leverage changes.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- Squat progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a3333333-3333-3333-3333-333333333333', 'Squat', 'legs', 'leverage',
     'Build leg strength from assisted squats to single-leg variations using leverage progression.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- Dip progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a4444444-4444-4444-4444-444444444444', 'Dip', 'chest', 'leverage',
     'Progress from bench dips to advanced ring dips through body position and stability challenges.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- Row progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a5555555-5555-5555-5555-555555555555', 'Row', 'back', 'leverage',
     'Develop pulling strength horizontally through row variations of increasing difficulty.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- Plank progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a6666666-6666-6666-6666-666666666666', 'Plank', 'core', 'leverage',
     'Build core stability through plank progressions that increase leverage demands.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- Lunge progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a7777777-7777-7777-7777-777777777777', 'Lunge', 'legs', 'leverage',
     'Develop unilateral leg strength through lunge variations with increasing balance demands.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- Hip hinge progression chain (leverage-based)
INSERT INTO exercise_variant_chains (id, base_exercise_name, muscle_group, chain_type, description) VALUES
    ('a8888888-8888-8888-8888-888888888888', 'Hip Hinge', 'legs', 'leverage',
     'Master the hip hinge pattern from basic to single-leg Romanian deadlift variations.')
ON CONFLICT (base_exercise_name, chain_type) DO NOTHING;

-- ============================================
-- SEED DATA: Push-up Variants (9 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a1111111-1111-1111-1111-111111111111', 'Wall Push-up', 1, 1,
     '{"min_reps": 20, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY[]::TEXT[],
     'Starting point for beginners. Stand arms length from wall.',
     ARRAY['Keep body in straight line', 'Elbows at 45 degrees', 'Full range of motion', 'Control the movement']),

    ('a1111111-1111-1111-1111-111111111111', 'Incline Push-up', 2, 2,
     '{"min_reps": 15, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Wall Push-up']::TEXT[],
     ARRAY['bench', 'stairs']::TEXT[],
     'Use sturdy elevated surface. Lower the incline as you progress.',
     ARRAY['Hands shoulder-width apart', 'Core tight throughout', 'Lower chest to surface', 'Press through palms']),

    ('a1111111-1111-1111-1111-111111111111', 'Knee Push-up', 2, 3,
     '{"min_reps": 15, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Incline Push-up']::TEXT[],
     ARRAY[]::TEXT[],
     'Cross ankles, maintain straight line from knees to shoulders.',
     ARRAY['Knees on soft surface', 'Hips aligned with shoulders', 'Full chest-to-floor depth', 'Do not let hips sag']),

    ('a1111111-1111-1111-1111-111111111111', 'Standard Push-up', 3, 4,
     '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Knee Push-up']::TEXT[],
     ARRAY[]::TEXT[],
     'The foundation movement. Master this before progressing.',
     ARRAY['Hands under shoulders', 'Core braced', 'Body forms straight line', 'Chest nearly touches floor']),

    ('a1111111-1111-1111-1111-111111111111', 'Diamond Push-up', 4, 5,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Standard Push-up']::TEXT[],
     ARRAY[]::TEXT[],
     'Hands together forming diamond shape. Emphasizes triceps.',
     ARRAY['Thumbs and index fingers form diamond', 'Keep elbows close to body', 'Lower chest to hands', 'Strong lockout at top']),

    ('a1111111-1111-1111-1111-111111111111', 'Decline Push-up', 5, 6,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Standard Push-up', 'Diamond Push-up']::TEXT[],
     ARRAY['bench', 'box']::TEXT[],
     'Feet elevated on bench or box. Targets upper chest and shoulders.',
     ARRAY['Feet elevated 12-24 inches', 'Hands slightly wider than shoulders', 'Control the descent', 'Full range of motion']),

    ('a1111111-1111-1111-1111-111111111111', 'Pike Push-up', 6, 7,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Decline Push-up']::TEXT[],
     ARRAY[]::TEXT[],
     'Hips high, body forms inverted V. Excellent shoulder development.',
     ARRAY['Hips as high as possible', 'Head goes forward between hands', 'Press through shoulders', 'Handstand pushup preparation']),

    ('a1111111-1111-1111-1111-111111111111', 'Archer Push-up', 7, 8,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Pike Push-up']::TEXT[],
     ARRAY[]::TEXT[],
     'Wide hand placement, lower to one side while extending the other arm.',
     ARRAY['Wide hand placement', 'Shift weight to working arm', 'Extended arm stays straight', 'Alternate sides each rep']),

    ('a1111111-1111-1111-1111-111111111111', 'One-Arm Push-up', 9, 9,
     '{"min_reps": 5, "min_sets": 3, "consecutive_sessions": 5}',
     ARRAY['Archer Push-up']::TEXT[],
     ARRAY[]::TEXT[],
     'The ultimate pushing strength test. Wide stance for balance.',
     ARRAY['Feet wide for balance', 'Free hand behind back', 'Keep hips level', 'Control the entire movement'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: Pull-up Variants (9 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a2222222-2222-2222-2222-222222222222', 'Dead Hang', 1, 1,
     '{"hold_seconds": 30, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'Build grip strength and shoulder stability. Foundation for all pulling.',
     ARRAY['Full arm extension', 'Shoulders away from ears', 'Grip the bar firmly', 'Breathe steadily']),

    ('a2222222-2222-2222-2222-222222222222', 'Scapular Pulls', 2, 2,
     '{"min_reps": 15, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Dead Hang']::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'Retract shoulder blades without bending arms. Crucial back activation.',
     ARRAY['Arms stay straight', 'Pull shoulder blades down and back', 'Small but controlled movement', 'Feel lats engage']),

    ('a2222222-2222-2222-2222-222222222222', 'Negative Pull-up', 3, 3,
     '{"min_reps": 8, "min_sets": 3, "time_under_tension_seconds": 5, "consecutive_sessions": 3}',
     ARRAY['Scapular Pulls']::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'Jump to top position, lower slowly for 5+ seconds. Great strength builder.',
     ARRAY['Jump or step to top position', 'Lower as slowly as possible', 'Control entire descent', 'Aim for 5+ second lowering']),

    ('a2222222-2222-2222-2222-222222222222', 'Assisted Pull-up', 3, 4,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Negative Pull-up']::TEXT[],
     ARRAY['pull-up bar', 'resistance band']::TEXT[],
     'Use band or machine for assistance. Reduce assistance over time.',
     ARRAY['Band under feet or knees', 'Pull chin over bar', 'Full extension at bottom', 'Control the movement']),

    ('a2222222-2222-2222-2222-222222222222', 'Full Pull-up', 5, 5,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Assisted Pull-up']::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'The standard pull-up. Chin clears bar with control.',
     ARRAY['Grip slightly wider than shoulders', 'Pull chin over bar', 'Full lockout at bottom', 'No kipping or swinging']),

    ('a2222222-2222-2222-2222-222222222222', 'Wide Grip Pull-up', 6, 6,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Full Pull-up']::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'Hands wider than shoulders. Emphasizes lats.',
     ARRAY['Hands 1.5x shoulder width', 'Pull to upper chest if possible', 'Full range of motion', 'Feel the lat stretch']),

    ('a2222222-2222-2222-2222-222222222222', 'L-Sit Pull-up', 7, 7,
     '{"min_reps": 6, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Full Pull-up']::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'Maintain L-sit position throughout. Core and grip intensive.',
     ARRAY['Legs parallel to ground', 'Point toes', 'Maintain L throughout pull', 'Strong core engagement']),

    ('a2222222-2222-2222-2222-222222222222', 'Archer Pull-up', 8, 8,
     '{"min_reps": 6, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Wide Grip Pull-up']::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'Pull to one side while extending other arm. One-arm preparation.',
     ARRAY['Wide grip start', 'Pull toward one hand', 'Other arm extends along bar', 'Alternate sides']),

    ('a2222222-2222-2222-2222-222222222222', 'One-Arm Pull-up', 10, 9,
     '{"min_reps": 3, "min_sets": 3, "consecutive_sessions": 5}',
     ARRAY['Archer Pull-up']::TEXT[],
     ARRAY['pull-up bar']::TEXT[],
     'The holy grail of pulling strength. Years of dedication required.',
     ARRAY['Start with assisted versions', 'Grip wrist then forearm', 'Eventually unassisted', 'Elite level achievement'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: Squat Variants (8 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a3333333-3333-3333-3333-333333333333', 'Assisted Squat', 1, 1,
     '{"min_reps": 20, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY[]::TEXT[],
     'Hold onto stable surface for balance. Focus on depth.',
     ARRAY['Hold wall or sturdy object', 'Sit back into heels', 'Knees track over toes', 'Go as deep as comfortable']),

    ('a3333333-3333-3333-3333-333333333333', 'Bodyweight Squat', 2, 2,
     '{"min_reps": 20, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Assisted Squat']::TEXT[],
     ARRAY[]::TEXT[],
     'No assistance needed. Arms forward for counterbalance.',
     ARRAY['Feet shoulder-width', 'Arms forward for balance', 'Chest up throughout', 'Full depth if mobile']),

    ('a3333333-3333-3333-3333-333333333333', 'Goblet Squat', 3, 3,
     '{"min_reps": 15, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Bodyweight Squat']::TEXT[],
     ARRAY['dumbbell', 'kettlebell']::TEXT[],
     'Hold weight at chest. Helps maintain upright torso.',
     ARRAY['Hold weight at chest level', 'Elbows inside knees at bottom', 'Drive through heels', 'Core stays tight']),

    ('a3333333-3333-3333-3333-333333333333', 'Split Squat', 4, 4,
     '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Bodyweight Squat']::TEXT[],
     ARRAY[]::TEXT[],
     'Staggered stance. Introduction to single-leg training.',
     ARRAY['Rear foot on toes', 'Front knee tracks over toes', 'Lower back knee toward floor', 'Torso stays upright']),

    ('a3333333-3333-3333-3333-333333333333', 'Bulgarian Split Squat', 5, 5,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Split Squat']::TEXT[],
     ARRAY['bench', 'box']::TEXT[],
     'Rear foot elevated on bench. Excellent unilateral development.',
     ARRAY['Rear foot elevated 12-18 inches', 'Front knee at 90 degrees at bottom', 'Control the descent', 'Keep torso upright']),

    ('a3333333-3333-3333-3333-333333333333', 'Skater Squat', 6, 6,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Bulgarian Split Squat']::TEXT[],
     ARRAY[]::TEXT[],
     'Single leg with rear leg hovering. Bridges to pistol squat.',
     ARRAY['Rear leg bent behind you', 'Hover knee above ground', 'Arms for counterbalance', 'Control the eccentric']),

    ('a3333333-3333-3333-3333-333333333333', 'Shrimp Squat', 7, 7,
     '{"min_reps": 6, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Skater Squat']::TEXT[],
     ARRAY[]::TEXT[],
     'Hold rear foot behind you, knee touches ground.',
     ARRAY['Grab rear foot behind', 'Lower until knee touches', 'Keep chest up', 'Incredible quad strength needed']),

    ('a3333333-3333-3333-3333-333333333333', 'Pistol Squat', 8, 8,
     '{"min_reps": 5, "min_sets": 3, "consecutive_sessions": 5}',
     ARRAY['Shrimp Squat', 'Skater Squat']::TEXT[],
     ARRAY[]::TEXT[],
     'Single leg squat with other leg extended forward. Gold standard.',
     ARRAY['Extended leg stays straight', 'Arms forward for balance', 'Full depth', 'Requires strength and mobility'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: Dip Variants (6 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a4444444-4444-4444-4444-444444444444', 'Bench Dip', 2, 1,
     '{"min_reps": 15, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY['bench']::TEXT[],
     'Hands on bench behind you, feet on floor. Entry-level dip.',
     ARRAY['Hands on bench edge', 'Fingers forward', 'Lower until 90 degree elbow bend', 'Press through palms']),

    ('a4444444-4444-4444-4444-444444444444', 'Feet Elevated Bench Dip', 3, 2,
     '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Bench Dip']::TEXT[],
     ARRAY['bench']::TEXT[],
     'Feet on second bench. Increases difficulty.',
     ARRAY['Feet elevated to hip height', 'Keep body close to bench', 'Full range of motion', 'Control the descent']),

    ('a4444444-4444-4444-4444-444444444444', 'Assisted Parallel Bar Dip', 4, 3,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Feet Elevated Bench Dip']::TEXT[],
     ARRAY['dip bars', 'resistance band']::TEXT[],
     'Use band or machine for assistance on parallel bars.',
     ARRAY['Band under knees or feet', 'Lean slightly forward for chest', 'Lower until shoulders below elbows', 'Strong lockout at top']),

    ('a4444444-4444-4444-4444-444444444444', 'Parallel Bar Dip', 5, 4,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Assisted Parallel Bar Dip']::TEXT[],
     ARRAY['dip bars']::TEXT[],
     'Full bodyweight dip on parallel bars.',
     ARRAY['Grip bars firmly', 'Slight forward lean for chest', 'Elbows to 90 degrees minimum', 'Control throughout']),

    ('a4444444-4444-4444-4444-444444444444', 'Weighted Dip', 6, 5,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Parallel Bar Dip']::TEXT[],
     ARRAY['dip bars', 'dip belt', 'weight plate']::TEXT[],
     'Add external load with belt or dumbbell between legs.',
     ARRAY['Secure weight properly', 'Same form as bodyweight', 'Start light and progress', 'Maintain control']),

    ('a4444444-4444-4444-4444-444444444444', 'Ring Dip', 7, 6,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 5}',
     ARRAY['Parallel Bar Dip']::TEXT[],
     ARRAY['gymnastics rings']::TEXT[],
     'Dips on unstable rings. Requires exceptional stability.',
     ARRAY['Turn rings out at top', 'Keep rings close to body', 'Control the instability', 'Advanced skill'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: Row Variants (6 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a5555555-5555-5555-5555-555555555555', 'Inverted Row (High Bar)', 2, 1,
     '{"min_reps": 15, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY['barbell', 'smith machine', 'TRX']::TEXT[],
     'Bar at chest height. Nearly vertical body position.',
     ARRAY['Grip bar overhand', 'Body forms straight line', 'Pull chest to bar', 'Squeeze shoulder blades']),

    ('a5555555-5555-5555-5555-555555555555', 'Inverted Row (Medium Bar)', 3, 2,
     '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Inverted Row (High Bar)']::TEXT[],
     ARRAY['barbell', 'smith machine', 'TRX']::TEXT[],
     'Bar at hip height. More horizontal body.',
     ARRAY['Lower the bar height', 'Maintain straight body', 'Pull to lower chest', 'Full arm extension']),

    ('a5555555-5555-5555-5555-555555555555', 'Inverted Row (Low Bar)', 4, 3,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Inverted Row (Medium Bar)']::TEXT[],
     ARRAY['barbell', 'smith machine', 'TRX']::TEXT[],
     'Bar at knee height. Body nearly parallel to floor.',
     ARRAY['Body almost horizontal', 'Heels on ground', 'Strong back squeeze', 'Control the lowering']),

    ('a5555555-5555-5555-5555-555555555555', 'Feet Elevated Inverted Row', 5, 4,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Inverted Row (Low Bar)']::TEXT[],
     ARRAY['barbell', 'bench']::TEXT[],
     'Feet on bench, body horizontal. Maximum difficulty.',
     ARRAY['Feet elevated to bar height', 'Body parallel to floor', 'Full range of motion', 'Squeeze at top']),

    ('a5555555-5555-5555-5555-555555555555', 'One-Arm Inverted Row', 6, 5,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Feet Elevated Inverted Row']::TEXT[],
     ARRAY['TRX', 'rings']::TEXT[],
     'Single arm pulling. Significant strength requirement.',
     ARRAY['Free arm on hip or extended', 'Prevent rotation', 'Full range of motion', 'Alternate sides']),

    ('a5555555-5555-5555-5555-555555555555', 'Archer Row', 7, 6,
     '{"min_reps": 6, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['One-Arm Inverted Row']::TEXT[],
     ARRAY['barbell', 'wide grip']::TEXT[],
     'Wide grip, pull to one side while extending other arm.',
     ARRAY['Very wide grip', 'Pull to one hand', 'Other arm straightens', 'Alternate sides'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: Plank Variants (6 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a6666666-6666-6666-6666-666666666666', 'Knee Plank', 1, 1,
     '{"hold_seconds": 30, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY[]::TEXT[],
     'Plank on knees. Entry point for core training.',
     ARRAY['Forearms on ground', 'Knees bent', 'Straight line from knees to head', 'Engage core']),

    ('a6666666-6666-6666-6666-666666666666', 'Standard Plank', 2, 2,
     '{"hold_seconds": 60, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Knee Plank']::TEXT[],
     ARRAY[]::TEXT[],
     'Full plank on forearms. Foundation core exercise.',
     ARRAY['Forearms parallel', 'Body in straight line', 'Core braced', 'Breathe normally']),

    ('a6666666-6666-6666-6666-666666666666', 'High Plank', 3, 3,
     '{"hold_seconds": 60, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Standard Plank']::TEXT[],
     ARRAY[]::TEXT[],
     'Plank on hands with arms extended. Push-up top position.',
     ARRAY['Hands under shoulders', 'Arms fully extended', 'Core tight', 'Neutral spine']),

    ('a6666666-6666-6666-6666-666666666666', 'Plank with Leg Lift', 4, 4,
     '{"hold_seconds": 30, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['High Plank']::TEXT[],
     ARRAY[]::TEXT[],
     'Alternate lifting legs while maintaining plank.',
     ARRAY['Lift one leg at a time', 'Keep hips level', 'No rotation', 'Controlled movement']),

    ('a6666666-6666-6666-6666-666666666666', 'Plank with Arm Reach', 5, 5,
     '{"hold_seconds": 30, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Plank with Leg Lift']::TEXT[],
     ARRAY[]::TEXT[],
     'Alternate extending arms while maintaining plank.',
     ARRAY['Extend one arm forward', 'Minimize hip movement', 'Core stays braced', 'Alternate sides']),

    ('a6666666-6666-6666-6666-666666666666', 'Extended Plank', 6, 6,
     '{"hold_seconds": 30, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Plank with Arm Reach']::TEXT[],
     ARRAY[]::TEXT[],
     'Hands placed further forward. Maximum leverage.',
     ARRAY['Hands well ahead of shoulders', 'Body forms longer lever', 'Extreme core demand', 'Advanced variation'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: Lunge Variants (6 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a7777777-7777-7777-7777-777777777777', 'Assisted Lunge', 1, 1,
     '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY[]::TEXT[],
     'Hold onto wall or sturdy object for balance.',
     ARRAY['Light hand support', 'Step forward into lunge', 'Back knee toward floor', 'Push through front heel']),

    ('a7777777-7777-7777-7777-777777777777', 'Static Lunge', 2, 2,
     '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Assisted Lunge']::TEXT[],
     ARRAY[]::TEXT[],
     'Stationary lunge position. No stepping.',
     ARRAY['Fixed stance', 'Lower and raise vertically', 'Keep torso upright', 'Both knees at 90 degrees']),

    ('a7777777-7777-7777-7777-777777777777', 'Forward Lunge', 3, 3,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Static Lunge']::TEXT[],
     ARRAY[]::TEXT[],
     'Step forward, lower, return to start.',
     ARRAY['Step forward dynamically', 'Control the landing', 'Push back to start', 'Alternate legs']),

    ('a7777777-7777-7777-7777-777777777777', 'Reverse Lunge', 4, 4,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Forward Lunge']::TEXT[],
     ARRAY[]::TEXT[],
     'Step backward into lunge. Often easier on knees.',
     ARRAY['Step back with control', 'Lower back knee toward floor', 'Push through front foot', 'Easier on knees than forward']),

    ('a7777777-7777-7777-7777-777777777777', 'Walking Lunge', 5, 5,
     '{"min_reps": 20, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Forward Lunge', 'Reverse Lunge']::TEXT[],
     ARRAY[]::TEXT[],
     'Continuous forward lunges covering distance.',
     ARRAY['Continuous forward motion', 'Drive through front heel', 'Keep torso upright', 'Maintain rhythm']),

    ('a7777777-7777-7777-7777-777777777777', 'Jump Lunge', 6, 6,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Walking Lunge']::TEXT[],
     ARRAY[]::TEXT[],
     'Explosive lunge with jump switch. High intensity.',
     ARRAY['Explode upward from lunge', 'Switch legs in air', 'Land softly', 'Maintain balance'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- SEED DATA: Hip Hinge Variants (6 levels)
-- ============================================

INSERT INTO exercise_variants (chain_id, exercise_name, difficulty_level, step_order, unlock_criteria, prerequisites, equipment_required, notes, form_cues) VALUES
    ('a8888888-8888-8888-8888-888888888888', 'Wall Hip Hinge', 1, 1,
     '{"min_reps": 15, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY[]::TEXT[],
     ARRAY[]::TEXT[],
     'Learn hinge pattern by touching wall with glutes.',
     ARRAY['Stand arms length from wall', 'Push hips back to touch wall', 'Slight knee bend', 'Feel hamstring stretch']),

    ('a8888888-8888-8888-8888-888888888888', 'Good Morning', 2, 2,
     '{"min_reps": 12, "min_sets": 3, "consecutive_sessions": 2}',
     ARRAY['Wall Hip Hinge']::TEXT[],
     ARRAY[]::TEXT[],
     'Hands behind head, hinge at hips. Pattern training.',
     ARRAY['Hands behind head', 'Hinge at hips not waist', 'Slight knee bend', 'Neutral spine throughout']),

    ('a8888888-8888-8888-8888-888888888888', 'Romanian Deadlift', 3, 3,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Good Morning']::TEXT[],
     ARRAY['dumbbells', 'barbell']::TEXT[],
     'Loaded hip hinge. Keep weight close to legs.',
     ARRAY['Weight stays close to legs', 'Lower until hamstring stretch', 'Hips push back', 'Drive hips forward to stand']),

    ('a8888888-8888-8888-8888-888888888888', 'Stiff-Leg Deadlift', 4, 4,
     '{"min_reps": 10, "min_sets": 3, "consecutive_sessions": 3}',
     ARRAY['Romanian Deadlift']::TEXT[],
     ARRAY['dumbbells', 'barbell']::TEXT[],
     'Minimal knee bend. Maximum hamstring emphasis.',
     ARRAY['Legs nearly straight', 'Hinge at hips', 'Lower as far as flexibility allows', 'Strong glute squeeze at top']),

    ('a8888888-8888-8888-8888-888888888888', 'Single-Leg Romanian Deadlift', 5, 5,
     '{"min_reps": 8, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Romanian Deadlift']::TEXT[],
     ARRAY['dumbbells']::TEXT[],
     'Unilateral hip hinge. Challenges balance and stability.',
     ARRAY['Stand on one leg', 'Rear leg extends back for balance', 'Hips stay square', 'Weight close to standing leg']),

    ('a8888888-8888-8888-8888-888888888888', 'Single-Leg Deadlift (Full ROM)', 6, 6,
     '{"min_reps": 6, "min_sets": 3, "consecutive_sessions": 4}',
     ARRAY['Single-Leg Romanian Deadlift']::TEXT[],
     ARRAY['dumbbells', 'kettlebell']::TEXT[],
     'Full range single-leg deadlift. Touch weight to floor.',
     ARRAY['Touch weight to floor', 'Maintain balance throughout', 'Control the entire movement', 'Posterior leg parallel at bottom'])
ON CONFLICT (chain_id, step_order) DO NOTHING;

-- ============================================
-- HELPER FUNCTION: Check if user is ready for progression
-- ============================================

CREATE OR REPLACE FUNCTION check_progression_readiness(
    p_user_id UUID,
    p_exercise_name VARCHAR(200)
)
RETURNS TABLE (
    is_ready BOOLEAN,
    current_exercise VARCHAR(200),
    next_exercise VARCHAR(200),
    chain_name VARCHAR(100),
    criteria_met JSONB,
    criteria_needed JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_mastery RECORD;
    v_current_variant RECORD;
    v_next_variant RECORD;
    v_chain RECORD;
    v_criteria_met JSONB;
BEGIN
    -- Get user mastery for this exercise
    SELECT * INTO v_mastery
    FROM user_exercise_mastery
    WHERE user_id = p_user_id AND exercise_name = p_exercise_name;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, p_exercise_name, NULL::VARCHAR(200), NULL::VARCHAR(100), '{}'::JSONB, '{}'::JSONB;
        RETURN;
    END IF;

    -- Find current variant in chain
    SELECT ev.*, evc.base_exercise_name
    INTO v_current_variant
    FROM exercise_variants ev
    JOIN exercise_variant_chains evc ON ev.chain_id = evc.id
    WHERE ev.exercise_name = p_exercise_name;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, p_exercise_name, NULL::VARCHAR(200), NULL::VARCHAR(100), '{}'::JSONB, '{}'::JSONB;
        RETURN;
    END IF;

    -- Get chain info
    SELECT * INTO v_chain
    FROM exercise_variant_chains
    WHERE id = v_current_variant.chain_id;

    -- Find next variant in chain
    SELECT * INTO v_next_variant
    FROM exercise_variants
    WHERE chain_id = v_current_variant.chain_id
    AND step_order = v_current_variant.step_order + 1;

    IF NOT FOUND THEN
        -- Already at top of chain
        RETURN QUERY SELECT FALSE, p_exercise_name, NULL::VARCHAR(200), v_chain.base_exercise_name, '{}'::JSONB, v_current_variant.unlock_criteria;
        RETURN;
    END IF;

    -- Build criteria met object
    v_criteria_met := jsonb_build_object(
        'current_max_reps', v_mastery.current_max_reps,
        'total_sessions', v_mastery.total_sessions,
        'consecutive_easy_sessions', v_mastery.consecutive_easy_sessions
    );

    -- Check if criteria met
    RETURN QUERY SELECT
        (v_mastery.current_max_reps >= COALESCE((v_current_variant.unlock_criteria->>'min_reps')::INT, 12)
         AND v_mastery.consecutive_easy_sessions >= COALESCE((v_current_variant.unlock_criteria->>'consecutive_sessions')::INT, 2)),
        p_exercise_name,
        v_next_variant.exercise_name,
        v_chain.base_exercise_name,
        v_criteria_met,
        v_current_variant.unlock_criteria;
END;
$$;

COMMENT ON FUNCTION check_progression_readiness IS 'Checks if a user is ready to progress to the next exercise variant in a chain';

-- ============================================
-- HELPER FUNCTION: Get suggested progressions for user
-- ============================================

CREATE OR REPLACE FUNCTION get_user_progression_suggestions(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    exercise_name VARCHAR(200),
    suggested_next VARCHAR(200),
    chain_name VARCHAR(100),
    muscle_group VARCHAR(50),
    consecutive_easy_sessions INTEGER,
    last_performed_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        uem.exercise_name,
        uem.suggested_next_variant,
        evc.base_exercise_name,
        evc.muscle_group,
        uem.consecutive_easy_sessions,
        uem.last_performed_at
    FROM user_exercise_mastery uem
    LEFT JOIN exercise_variant_chains evc ON uem.chain_id = evc.id
    WHERE uem.user_id = p_user_id
    AND uem.ready_for_progression = TRUE
    AND uem.suggested_next_variant IS NOT NULL
    ORDER BY uem.consecutive_easy_sessions DESC, uem.last_performed_at DESC
    LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION get_user_progression_suggestions IS 'Returns exercises the user is ready to progress from';

-- ============================================
-- VIEW: Progression chain overview
-- ============================================

CREATE OR REPLACE VIEW v_exercise_progression_overview AS
SELECT
    evc.id AS chain_id,
    evc.base_exercise_name,
    evc.muscle_group,
    evc.chain_type,
    evc.description AS chain_description,
    ev.id AS variant_id,
    ev.exercise_name,
    ev.difficulty_level,
    ev.step_order,
    ev.unlock_criteria,
    ev.prerequisites,
    ev.equipment_required,
    ev.notes,
    ev.form_cues
FROM exercise_variant_chains evc
JOIN exercise_variants ev ON evc.id = ev.chain_id
ORDER BY evc.base_exercise_name, ev.step_order;

COMMENT ON VIEW v_exercise_progression_overview IS 'Combined view of all exercise progression chains with their variants';

-- Grant access to authenticated users
GRANT SELECT ON v_exercise_progression_overview TO authenticated;

-- ============================================
-- DOCUMENTATION
-- ============================================

COMMENT ON TABLE exercise_variant_chains IS 'Progression chains grouping related exercises from beginner to advanced';
COMMENT ON TABLE exercise_variants IS 'Individual exercise variants within progression chains with difficulty and unlock criteria';
COMMENT ON TABLE user_exercise_mastery IS 'Tracks user progress and mastery level for each exercise performed';
COMMENT ON TABLE user_rep_range_preferences IS 'User preferences for rep ranges and progression style';
COMMENT ON TABLE progression_history IS 'Audit log of all exercise progressions and regressions';

-- ============================================
-- SUMMARY
-- ============================================
-- This migration creates:
-- 1. exercise_variant_chains - 8 progression chains (Push-up, Pull-up, Squat, Dip, Row, Plank, Lunge, Hip Hinge)
-- 2. exercise_variants - 52 exercise variants across all chains
-- 3. user_exercise_mastery - Per-user tracking of exercise performance
-- 4. user_rep_range_preferences - User training style preferences
-- 5. progression_history - Audit trail of progressions
-- 6. Helper functions for checking readiness and getting suggestions
-- 7. Overview view for easy querying
-- 8. Proper RLS policies for security
-- 9. Indexes for performance
