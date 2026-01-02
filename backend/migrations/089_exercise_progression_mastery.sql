-- Exercise Progression Mastery Migration
-- Tracks user readiness for exercise progressions based on feedback
-- Integrates feedback system with leverage-based exercise variants

-- ============================================
-- USER EXERCISE MASTERY TABLE
-- ============================================
-- Tracks consecutive "too easy" sessions and progression readiness

CREATE TABLE IF NOT EXISTS user_exercise_mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    exercise_name VARCHAR(200) NOT NULL,

    -- Feedback tracking
    consecutive_easy_sessions INTEGER DEFAULT 0,
    consecutive_hard_sessions INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,

    -- Progression status
    ready_for_progression BOOLEAN DEFAULT FALSE,
    suggested_next_variant VARCHAR(200),
    progression_chain_id UUID REFERENCES exercise_progression_chains(id),

    -- Decline tracking (to avoid spamming)
    last_progression_suggested_at TIMESTAMP WITH TIME ZONE,
    progression_declined_at TIMESTAMP WITH TIME ZONE,
    decline_reason VARCHAR(500),
    progression_accepted_count INTEGER DEFAULT 0,
    progression_declined_count INTEGER DEFAULT 0,

    -- Timestamps
    first_performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, exercise_name)
);

-- ============================================
-- EXERCISE VARIANT CHAINS TABLE
-- ============================================
-- Defines progression chains for weighted/leverage exercises
-- Similar to skill progressions but for strength-based variants

CREATE TABLE IF NOT EXISTS exercise_variant_chains (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    base_exercise_name VARCHAR(200) NOT NULL,  -- e.g., "Push-up", "Squat"
    category VARCHAR(50),  -- push, pull, legs, core
    equipment_type VARCHAR(50),  -- bodyweight, dumbbell, barbell, machine
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(base_exercise_name)
);

-- ============================================
-- EXERCISE VARIANT STEPS TABLE
-- ============================================
-- Ordered variants from easiest to hardest

CREATE TABLE IF NOT EXISTS exercise_variant_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chain_id UUID REFERENCES exercise_variant_chains(id) ON DELETE CASCADE,
    exercise_name VARCHAR(200) NOT NULL,
    variant_order INTEGER NOT NULL,  -- 1 = easiest, higher = harder
    difficulty_modifier DECIMAL(3,2) DEFAULT 1.0,  -- Relative difficulty (1.0 = baseline)
    leverage_factor VARCHAR(50),  -- "easier_leverage", "standard", "harder_leverage"
    description TEXT,
    tips TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(chain_id, variant_order)
);

-- ============================================
-- PROGRESSION HISTORY TABLE
-- ============================================
-- Tracks when users accept/decline progressions

CREATE TABLE IF NOT EXISTS progression_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    from_exercise VARCHAR(200) NOT NULL,
    to_exercise VARCHAR(200) NOT NULL,
    chain_id UUID REFERENCES exercise_variant_chains(id),
    action VARCHAR(20) NOT NULL CHECK (action IN ('accepted', 'declined', 'suggested')),
    reason VARCHAR(500),
    context JSONB,  -- Additional context like {source: "feedback", difficulty_felt: "too_easy"}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_exercise_mastery_user ON user_exercise_mastery(user_id);
CREATE INDEX IF NOT EXISTS idx_user_exercise_mastery_exercise ON user_exercise_mastery(exercise_name);
CREATE INDEX IF NOT EXISTS idx_user_exercise_mastery_ready ON user_exercise_mastery(user_id, ready_for_progression) WHERE ready_for_progression = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_exercise_mastery_updated ON user_exercise_mastery(user_id, updated_at);

CREATE INDEX IF NOT EXISTS idx_exercise_variant_chains_base ON exercise_variant_chains(base_exercise_name);
CREATE INDEX IF NOT EXISTS idx_exercise_variant_chains_category ON exercise_variant_chains(category);

CREATE INDEX IF NOT EXISTS idx_exercise_variant_steps_chain ON exercise_variant_steps(chain_id);
CREATE INDEX IF NOT EXISTS idx_exercise_variant_steps_order ON exercise_variant_steps(chain_id, variant_order);
CREATE INDEX IF NOT EXISTS idx_exercise_variant_steps_name ON exercise_variant_steps(exercise_name);

CREATE INDEX IF NOT EXISTS idx_progression_history_user ON progression_history(user_id);
CREATE INDEX IF NOT EXISTS idx_progression_history_created ON progression_history(user_id, created_at);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE user_exercise_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_variant_chains ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_variant_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE progression_history ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own mastery data
DROP POLICY IF EXISTS "Users manage own exercise mastery" ON user_exercise_mastery;
CREATE POLICY "Users manage own exercise mastery" ON user_exercise_mastery FOR ALL USING (auth.uid() = user_id);

-- Public read for variant chains and steps
DROP POLICY IF EXISTS "Anyone can read variant chains" ON exercise_variant_chains;
CREATE POLICY "Anyone can read variant chains" ON exercise_variant_chains FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can read variant steps" ON exercise_variant_steps;
CREATE POLICY "Anyone can read variant steps" ON exercise_variant_steps FOR SELECT USING (true);

-- Users can only see their own progression history
DROP POLICY IF EXISTS "Users manage own progression history" ON progression_history;
CREATE POLICY "Users manage own progression history" ON progression_history FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- SEED DATA: EXERCISE VARIANT CHAINS
-- ============================================

-- Push-up variants (bodyweight)
INSERT INTO exercise_variant_chains (id, base_exercise_name, category, equipment_type, description) VALUES
    ('a1111111-1111-1111-1111-111111111111', 'Push-up', 'push', 'bodyweight',
     'Push-up progressions from wall to one-arm variations')
ON CONFLICT (base_exercise_name) DO NOTHING;

INSERT INTO exercise_variant_steps (chain_id, exercise_name, variant_order, difficulty_modifier, leverage_factor, description, tips) VALUES
    ('a1111111-1111-1111-1111-111111111111', 'Wall Push-ups', 1, 0.4, 'easier_leverage',
     'Standing push-up against wall', 'Keep core tight, full range of motion'),
    ('a1111111-1111-1111-1111-111111111111', 'Incline Push-ups', 2, 0.6, 'easier_leverage',
     'Push-ups with hands elevated on bench', 'Lower the incline as you progress'),
    ('a1111111-1111-1111-1111-111111111111', 'Knee Push-ups', 3, 0.7, 'easier_leverage',
     'Push-ups from knees', 'Keep hips in line with shoulders'),
    ('a1111111-1111-1111-1111-111111111111', 'Standard Push-ups', 4, 1.0, 'standard',
     'Full bodyweight push-up', 'Hands shoulder-width, elbows at 45 degrees'),
    ('a1111111-1111-1111-1111-111111111111', 'Diamond Push-ups', 5, 1.2, 'harder_leverage',
     'Hands together in diamond shape', 'Excellent triceps builder'),
    ('a1111111-1111-1111-1111-111111111111', 'Decline Push-ups', 6, 1.3, 'harder_leverage',
     'Feet elevated on bench', 'Targets upper chest more'),
    ('a1111111-1111-1111-1111-111111111111', 'Archer Push-ups', 7, 1.5, 'harder_leverage',
     'Wide arms, lower to one side', 'Preparation for one-arm push-up'),
    ('a1111111-1111-1111-1111-111111111111', 'One-Arm Push-ups', 8, 2.0, 'harder_leverage',
     'Single arm push-up', 'Elite pushing strength')
ON CONFLICT (chain_id, variant_order) DO NOTHING;

-- Pull-up variants (bodyweight)
INSERT INTO exercise_variant_chains (id, base_exercise_name, category, equipment_type, description) VALUES
    ('a2222222-2222-2222-2222-222222222222', 'Pull-up', 'pull', 'bodyweight',
     'Pull-up progressions from dead hang to one-arm')
ON CONFLICT (base_exercise_name) DO NOTHING;

INSERT INTO exercise_variant_steps (chain_id, exercise_name, variant_order, difficulty_modifier, leverage_factor, description, tips) VALUES
    ('a2222222-2222-2222-2222-222222222222', 'Dead Hang', 1, 0.3, 'easier_leverage',
     'Hang from bar with straight arms', 'Build grip strength and shoulder stability'),
    ('a2222222-2222-2222-2222-222222222222', 'Scapular Pulls', 2, 0.4, 'easier_leverage',
     'Pull shoulder blades without bending arms', 'Small movement, big back activation'),
    ('a2222222-2222-2222-2222-222222222222', 'Band-Assisted Pull-ups', 3, 0.6, 'easier_leverage',
     'Pull-ups with resistance band', 'Reduce band thickness as you progress'),
    ('a2222222-2222-2222-2222-222222222222', 'Negative Pull-ups', 4, 0.7, 'easier_leverage',
     'Jump up, lower slowly', 'Aim for 5+ second descents'),
    ('a2222222-2222-2222-2222-222222222222', 'Full Pull-ups', 5, 1.0, 'standard',
     'Chin above bar, full extension', 'No kipping, control the movement'),
    ('a2222222-2222-2222-2222-222222222222', 'Wide Grip Pull-ups', 6, 1.1, 'standard',
     'Hands wider than shoulder width', 'Targets lats more'),
    ('a2222222-2222-2222-2222-222222222222', 'L-Sit Pull-ups', 7, 1.4, 'harder_leverage',
     'Pull-ups with legs extended horizontal', 'Core and pulling combination'),
    ('a2222222-2222-2222-2222-222222222222', 'Archer Pull-ups', 8, 1.6, 'harder_leverage',
     'Wide grip, pull to one side', 'One-arm prep'),
    ('a2222222-2222-2222-2222-222222222222', 'One-Arm Pull-ups', 9, 2.5, 'harder_leverage',
     'Single arm pull-up', 'Ultimate pulling strength')
ON CONFLICT (chain_id, variant_order) DO NOTHING;

-- Squat variants (bodyweight)
INSERT INTO exercise_variant_chains (id, base_exercise_name, category, equipment_type, description) VALUES
    ('a3333333-3333-3333-3333-333333333333', 'Squat', 'legs', 'bodyweight',
     'Squat progressions from assisted to pistol')
ON CONFLICT (base_exercise_name) DO NOTHING;

INSERT INTO exercise_variant_steps (chain_id, exercise_name, variant_order, difficulty_modifier, leverage_factor, description, tips) VALUES
    ('a3333333-3333-3333-3333-333333333333', 'Assisted Squats', 1, 0.5, 'easier_leverage',
     'Holding onto support for balance', 'Focus on depth and form'),
    ('a3333333-3333-3333-3333-333333333333', 'Bodyweight Squats', 2, 1.0, 'standard',
     'Standard squat without assistance', 'Knees track over toes'),
    ('a3333333-3333-3333-3333-333333333333', 'Jump Squats', 3, 1.2, 'standard',
     'Explosive squat with jump', 'Land softly'),
    ('a3333333-3333-3333-3333-333333333333', 'Bulgarian Split Squats', 4, 1.3, 'harder_leverage',
     'Rear foot elevated', 'Great single-leg strength'),
    ('a3333333-3333-3333-3333-333333333333', 'Shrimp Squats', 5, 1.6, 'harder_leverage',
     'Hold rear foot, knee to floor', 'Incredible quad strength'),
    ('a3333333-3333-3333-3333-333333333333', 'Pistol Squats', 6, 2.0, 'harder_leverage',
     'Single leg squat, other leg extended', 'Gold standard leg exercise')
ON CONFLICT (chain_id, variant_order) DO NOTHING;

-- Dumbbell Bench Press variants
INSERT INTO exercise_variant_chains (id, base_exercise_name, category, equipment_type, description) VALUES
    ('a4444444-4444-4444-4444-444444444444', 'Dumbbell Bench Press', 'push', 'dumbbell',
     'Dumbbell pressing progressions with grip and angle variations')
ON CONFLICT (base_exercise_name) DO NOTHING;

INSERT INTO exercise_variant_steps (chain_id, exercise_name, variant_order, difficulty_modifier, leverage_factor, description, tips) VALUES
    ('a4444444-4444-4444-4444-444444444444', 'Dumbbell Floor Press', 1, 0.8, 'easier_leverage',
     'Press from floor, limited ROM', 'Good for shoulder health'),
    ('a4444444-4444-4444-4444-444444444444', 'Flat Dumbbell Press', 2, 1.0, 'standard',
     'Standard dumbbell bench press', 'Control the descent'),
    ('a4444444-4444-4444-4444-444444444444', 'Incline Dumbbell Press', 3, 1.1, 'standard',
     'Bench at 30-45 degree angle', 'Targets upper chest'),
    ('a4444444-4444-4444-4444-444444444444', 'Single-Arm Dumbbell Press', 4, 1.3, 'harder_leverage',
     'One arm at a time for core stability', 'Excellent anti-rotation work')
ON CONFLICT (chain_id, variant_order) DO NOTHING;

-- Barbell Row variants
INSERT INTO exercise_variant_chains (id, base_exercise_name, category, equipment_type, description) VALUES
    ('a5555555-5555-5555-5555-555555555555', 'Barbell Row', 'pull', 'barbell',
     'Rowing progressions with different grips and body positions')
ON CONFLICT (base_exercise_name) DO NOTHING;

INSERT INTO exercise_variant_steps (chain_id, exercise_name, variant_order, difficulty_modifier, leverage_factor, description, tips) VALUES
    ('a5555555-5555-5555-5555-555555555555', 'Chest-Supported Row', 1, 0.7, 'easier_leverage',
     'Row with chest on incline bench', 'Less lower back stress'),
    ('a5555555-5555-5555-5555-555555555555', 'Bent Over Row', 2, 1.0, 'standard',
     'Standard barbell row', 'Keep back flat, pull to belly'),
    ('a5555555-5555-5555-5555-555555555555', 'Pendlay Row', 3, 1.1, 'standard',
     'Row from floor each rep', 'More explosive, strict form'),
    ('a5555555-5555-5555-5555-555555555555', 'Yates Row', 4, 0.9, 'standard',
     'Underhand grip, more upright', 'Targets biceps more')
ON CONFLICT (chain_id, variant_order) DO NOTHING;

-- ============================================
-- FUNCTION: Find next progression variant
-- ============================================

CREATE OR REPLACE FUNCTION find_next_exercise_variant(
    p_exercise_name VARCHAR(200)
) RETURNS TABLE (
    chain_id UUID,
    current_exercise VARCHAR(200),
    next_exercise VARCHAR(200),
    current_order INTEGER,
    next_order INTEGER,
    difficulty_increase DECIMAL(3,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id as chain_id,
        curr.exercise_name as current_exercise,
        next.exercise_name as next_exercise,
        curr.variant_order as current_order,
        next.variant_order as next_order,
        next.difficulty_modifier - curr.difficulty_modifier as difficulty_increase
    FROM exercise_variant_chains c
    JOIN exercise_variant_steps curr ON curr.chain_id = c.id
    JOIN exercise_variant_steps next ON next.chain_id = c.id
        AND next.variant_order = curr.variant_order + 1
    WHERE LOWER(curr.exercise_name) = LOWER(p_exercise_name)
       OR LOWER(c.base_exercise_name) = LOWER(p_exercise_name);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE user_exercise_mastery IS 'Tracks user mastery and progression readiness for exercises';
COMMENT ON TABLE exercise_variant_chains IS 'Defines exercise progression chains based on leverage/difficulty';
COMMENT ON TABLE exercise_variant_steps IS 'Individual exercise variants within a chain, ordered by difficulty';
COMMENT ON TABLE progression_history IS 'Audit log of progression suggestions and user responses';

COMMENT ON COLUMN user_exercise_mastery.consecutive_easy_sessions IS 'Count of consecutive sessions where user rated exercise as too_easy';
COMMENT ON COLUMN user_exercise_mastery.ready_for_progression IS 'TRUE when user has 2+ consecutive easy sessions and next variant exists';
COMMENT ON COLUMN user_exercise_mastery.last_progression_suggested_at IS 'When progression was last suggested (for rate limiting)';
COMMENT ON COLUMN exercise_variant_steps.difficulty_modifier IS 'Relative difficulty: 1.0 = standard, <1.0 = easier, >1.0 = harder';
COMMENT ON COLUMN exercise_variant_steps.leverage_factor IS 'Categorizes the leverage advantage: easier_leverage, standard, harder_leverage';
