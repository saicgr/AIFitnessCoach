-- Migration 128: Gender-Specific and Hormonal Exercise Columns
-- Description: Adds columns to exercises table for gender-specific targeting,
--              kegel identification, and hormonal support categorization
-- Date: 2025-01-01

-- ============================================================================
-- ADD COLUMNS TO EXERCISES TABLE
-- ============================================================================

-- Target gender for exercises (some exercises are more suited for specific genders)
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS target_gender VARCHAR(20) DEFAULT 'all';
COMMENT ON COLUMN exercises.target_gender IS 'Target gender: all, male, female';

-- Flag for kegel/pelvic floor exercises
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS is_kegel BOOLEAN DEFAULT FALSE;
COMMENT ON COLUMN exercises.is_kegel IS 'Whether this is a pelvic floor/kegel exercise';

-- Hormone support categories (array for multi-select)
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS hormone_support TEXT[] DEFAULT '{}';
COMMENT ON COLUMN exercises.hormone_support IS 'Hormone goals this exercise supports: testosterone, estrogen_balance, pcos, menopause, fertility';

-- Cycle phase recommendations (array for multi-select)
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS cycle_phase_recommended TEXT[] DEFAULT '{}';
COMMENT ON COLUMN exercises.cycle_phase_recommended IS 'Menstrual cycle phases this exercise is good for: menstrual, follicular, ovulation, luteal';

-- Specific hormone flags for easy querying
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS testosterone_boosting BOOLEAN DEFAULT FALSE;
COMMENT ON COLUMN exercises.testosterone_boosting IS 'Exercise particularly good for testosterone optimization';

ALTER TABLE exercises ADD COLUMN IF NOT EXISTS pcos_friendly BOOLEAN DEFAULT FALSE;
COMMENT ON COLUMN exercises.pcos_friendly IS 'Exercise suitable for PCOS management (moderate intensity, insulin-sensitizing)';

ALTER TABLE exercises ADD COLUMN IF NOT EXISTS menopause_friendly BOOLEAN DEFAULT FALSE;
COMMENT ON COLUMN exercises.menopause_friendly IS 'Exercise suitable for menopause (bone health, balance, moderate intensity)';

ALTER TABLE exercises ADD COLUMN IF NOT EXISTS fertility_supportive BOOLEAN DEFAULT FALSE;
COMMENT ON COLUMN exercises.fertility_supportive IS 'Exercise supportive of fertility (moderate, stress-reducing)';

ALTER TABLE exercises ADD COLUMN IF NOT EXISTS postpartum_safe BOOLEAN DEFAULT FALSE;
COMMENT ON COLUMN exercises.postpartum_safe IS 'Exercise safe for early postpartum recovery';

-- ============================================================================
-- INDEXES FOR EFFICIENT QUERYING
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_exercises_target_gender ON exercises(target_gender) WHERE target_gender != 'all';
CREATE INDEX IF NOT EXISTS idx_exercises_is_kegel ON exercises(is_kegel) WHERE is_kegel = true;
CREATE INDEX IF NOT EXISTS idx_exercises_testosterone ON exercises(testosterone_boosting) WHERE testosterone_boosting = true;
CREATE INDEX IF NOT EXISTS idx_exercises_pcos ON exercises(pcos_friendly) WHERE pcos_friendly = true;
CREATE INDEX IF NOT EXISTS idx_exercises_menopause ON exercises(menopause_friendly) WHERE menopause_friendly = true;
CREATE INDEX IF NOT EXISTS idx_exercises_fertility ON exercises(fertility_supportive) WHERE fertility_supportive = true;
CREATE INDEX IF NOT EXISTS idx_exercises_postpartum ON exercises(postpartum_safe) WHERE postpartum_safe = true;

-- GIN index for array columns
CREATE INDEX IF NOT EXISTS idx_exercises_hormone_support ON exercises USING GIN(hormone_support) WHERE hormone_support != '{}';
CREATE INDEX IF NOT EXISTS idx_exercises_cycle_phase ON exercises USING GIN(cycle_phase_recommended) WHERE cycle_phase_recommended != '{}';

-- ============================================================================
-- UPDATE EXISTING EXERCISES WITH HORMONAL METADATA
-- ============================================================================

-- 1. Mark COMPOUND exercises as TESTOSTERONE-BOOSTING
-- These are heavy multi-joint movements that stimulate testosterone production
UPDATE exercises SET
    testosterone_boosting = true,
    hormone_support = CASE
        WHEN 'testosterone' = ANY(hormone_support) THEN hormone_support
        ELSE array_append(COALESCE(hormone_support, '{}'), 'testosterone')
    END,
    cycle_phase_recommended = ARRAY['follicular', 'ovulation']
WHERE (
    -- By category/subcategory
    (category = 'strength' AND subcategory = 'compound')
    OR is_compound = true
    -- By name patterns (common compound exercises)
    OR name ILIKE '%squat%'
    OR name ILIKE '%deadlift%'
    OR name ILIKE '%bench press%'
    OR name ILIKE '%overhead press%'
    OR name ILIKE '%military press%'
    OR name ILIKE '%barbell row%'
    OR name ILIKE '%pull%up%'
    OR name ILIKE '%chin%up%'
    OR name ILIKE '%dip%'
    OR name ILIKE '%leg press%'
    OR name ILIKE '%hip thrust%'
    OR name ILIKE '%clean%'
    OR name ILIKE '%snatch%'
    -- By primary muscle for large muscle groups
    OR primary_muscle IN ('quadriceps', 'glutes', 'hamstrings', 'back', 'chest')
);

-- 2. Mark LOW-IMPACT exercises as PCOS-FRIENDLY
-- PCOS benefits from moderate, consistent exercise that improves insulin sensitivity
UPDATE exercises SET
    pcos_friendly = true,
    hormone_support = CASE
        WHEN 'pcos' = ANY(hormone_support) THEN hormone_support
        ELSE array_append(COALESCE(hormone_support, '{}'), 'pcos')
    END,
    cycle_phase_recommended = ARRAY['menstrual', 'follicular', 'ovulation', 'luteal']
WHERE (
    -- Moderate intensity exercises
    category IN ('cardio', 'flexibility', 'mobility')
    OR subcategory IN ('isolation', 'stabilization')
    -- By name patterns
    OR name ILIKE '%walk%'
    OR name ILIKE '%yoga%'
    OR name ILIKE '%pilates%'
    OR name ILIKE '%stretch%'
    OR name ILIKE '%band%'
    OR name ILIKE '%cable%'
    OR name ILIKE '%machine%'
    -- Core exercises (insulin sensitivity)
    OR primary_muscle IN ('core', 'abs', 'abdominals')
    -- Low difficulty
    OR difficulty_level <= 2
);

-- 3. Mark WEIGHT-BEARING exercises as MENOPAUSE-FRIENDLY
-- Critical for bone health during menopause
UPDATE exercises SET
    menopause_friendly = true,
    hormone_support = CASE
        WHEN 'menopause' = ANY(hormone_support) THEN hormone_support
        ELSE array_append(COALESCE(hormone_support, '{}'), 'menopause')
    END
WHERE (
    -- Weight-bearing lower body
    name ILIKE '%squat%'
    OR name ILIKE '%lunge%'
    OR name ILIKE '%step up%'
    OR name ILIKE '%step-up%'
    OR name ILIKE '%leg press%'
    -- Upper body resistance
    OR name ILIKE '%press%'
    OR name ILIKE '%row%'
    OR name ILIKE '%curl%'
    -- Standing exercises (load spine)
    OR name ILIKE '%standing%'
    -- Any resistance training
    OR category = 'strength'
    -- Balance exercises (fall prevention)
    OR name ILIKE '%balance%'
    OR name ILIKE '%single leg%'
    OR name ILIKE '%single-leg%'
);

-- 4. Mark GENTLE exercises as FERTILITY-SUPPORTIVE
-- Moderate exercise supports fertility; avoid excessive intensity
UPDATE exercises SET
    fertility_supportive = true,
    hormone_support = CASE
        WHEN 'fertility' = ANY(hormone_support) THEN hormone_support
        ELSE array_append(COALESCE(hormone_support, '{}'), 'fertility')
    END,
    cycle_phase_recommended = ARRAY['follicular', 'ovulation']
WHERE (
    -- Gentle, restorative movements
    name ILIKE '%yoga%'
    OR name ILIKE '%stretch%'
    OR name ILIKE '%pilates%'
    OR name ILIKE '%bridge%'
    OR name ILIKE '%bird dog%'
    OR name ILIKE '%bird-dog%'
    OR name ILIKE '%dead bug%'
    OR name ILIKE '%dead-bug%'
    OR name ILIKE '%cat cow%'
    OR name ILIKE '%cat-cow%'
    OR name ILIKE '%pelvic%'
    OR name ILIKE '%kegel%'
    OR name ILIKE '%breathing%'
    OR name ILIKE '%meditation%'
    OR name ILIKE '%relax%'
    -- Low impact
    OR category = 'flexibility'
    OR category = 'mobility'
    OR difficulty_level = 1
);

-- 5. Mark POSTPARTUM-SAFE exercises
-- Gentle core and pelvic floor rebuilding
UPDATE exercises SET
    postpartum_safe = true
WHERE (
    -- Gentle core work
    name ILIKE '%bridge%'
    OR name ILIKE '%bird dog%'
    OR name ILIKE '%bird-dog%'
    OR name ILIKE '%dead bug%'
    OR name ILIKE '%dead-bug%'
    OR name ILIKE '%pelvic%'
    OR name ILIKE '%kegel%'
    OR name ILIKE '%breathing%'
    OR name ILIKE '%diaphragm%'
    -- Gentle stretching
    OR name ILIKE '%stretch%'
    OR name ILIKE '%yoga%'
    -- Walking
    OR name ILIKE '%walk%'
    -- Low difficulty
    OR (difficulty_level = 1 AND category IN ('flexibility', 'mobility'))
);

-- 6. Mark ESTROGEN-BALANCING exercises
-- Mix of cardio and strength supports healthy estrogen metabolism
UPDATE exercises SET
    hormone_support = CASE
        WHEN 'estrogen_balance' = ANY(hormone_support) THEN hormone_support
        ELSE array_append(COALESCE(hormone_support, '{}'), 'estrogen_balance')
    END
WHERE (
    -- Cardio (supports liver function for estrogen metabolism)
    category = 'cardio'
    OR name ILIKE '%walk%'
    OR name ILIKE '%run%'
    OR name ILIKE '%jog%'
    OR name ILIKE '%cycle%'
    OR name ILIKE '%swim%'
    -- Strength (muscle mass helps hormone balance)
    OR (category = 'strength' AND difficulty_level <= 3)
    -- Core work (supports overall hormone health)
    OR primary_muscle IN ('core', 'abs', 'abdominals')
);

-- 7. Set CYCLE PHASE recommendations for menstrual phase
-- Low intensity exercises for menstrual phase
UPDATE exercises SET
    cycle_phase_recommended =
        CASE
            WHEN 'menstrual' = ANY(cycle_phase_recommended) THEN cycle_phase_recommended
            ELSE array_append(COALESCE(cycle_phase_recommended, '{}'), 'menstrual')
        END
WHERE (
    -- Gentle activities
    name ILIKE '%yoga%'
    OR name ILIKE '%stretch%'
    OR name ILIKE '%walk%'
    OR name ILIKE '%pilates%'
    OR category = 'flexibility'
    OR category = 'mobility'
    OR difficulty_level = 1
);

-- 8. Set CYCLE PHASE recommendations for luteal phase
-- Moderate intensity, avoid new maxes
UPDATE exercises SET
    cycle_phase_recommended =
        CASE
            WHEN 'luteal' = ANY(cycle_phase_recommended) THEN cycle_phase_recommended
            ELSE array_append(COALESCE(cycle_phase_recommended, '{}'), 'luteal')
        END
WHERE (
    -- Moderate intensity
    difficulty_level <= 3
    OR category IN ('flexibility', 'mobility', 'cardio')
    OR name ILIKE '%yoga%'
    OR name ILIKE '%pilates%'
    OR name ILIKE '%machine%'
    OR name ILIKE '%cable%'
);

-- ============================================================================
-- INSERT GENDER-SPECIFIC AND HORMONAL EXERCISES
-- ============================================================================

-- Kegel/Pelvic Floor Exercises (if not in kegel_exercises table already)
-- Note: Using correct column names from schema: primary_muscle, secondary_muscles, difficulty_level
INSERT INTO exercises (
    external_id, name,
    primary_muscle, secondary_muscles, equipment, body_part, target,
    difficulty_level, category, instructions,
    target_gender, is_kegel, hormone_support,
    testosterone_boosting, pcos_friendly, menopause_friendly,
    fertility_supportive, postpartum_safe,
    cycle_phase_recommended
) VALUES
-- General Pelvic Floor
('hormonal_basic_kegel', 'Basic Kegel Hold',
 'pelvic_floor', '["core"]'::jsonb, 'body weight', 'waist', 'pelvic_floor',
 1, 'pelvic_floor', 'Sit or lie down comfortably. Squeeze pelvic floor muscles. Hold for 5 seconds. Release and relax. Repeat 10 times.',
 'all', true, ARRAY['testosterone', 'estrogen_balance', 'fertility'],
 true, true, true, true, true,
 ARRAY['menstrual', 'follicular', 'ovulation', 'luteal']),

('hormonal_kegel_quick_flicks', 'Kegel Quick Flicks',
 'pelvic_floor', '["core"]'::jsonb, 'body weight', 'waist', 'pelvic_floor',
 1, 'pelvic_floor', 'Get comfortable. Quickly squeeze pelvic floor. Immediately release. Repeat rapidly 20 times.',
 'all', true, ARRAY['fertility'],
 false, true, true, true, true,
 ARRAY['follicular', 'ovulation']),

-- Male-Specific
('hormonal_reverse_kegel_male', 'Male Reverse Kegel',
 'pelvic_floor', '["core"]'::jsonb, 'body weight', 'waist', 'pelvic_floor',
 2, 'pelvic_floor', 'Sit comfortably. Take a deep breath. Consciously relax pelvic floor. Feel muscles drop and open. Hold relaxed state for 5 seconds.',
 'male', true, ARRAY['testosterone'],
 true, false, false, true, false,
 ARRAY['follicular', 'ovulation']),

('hormonal_prostate_support_kegel', 'Prostate Support Kegels',
 'pelvic_floor', '["core"]'::jsonb, 'body weight', 'waist', 'pelvic_floor',
 1, 'pelvic_floor', 'Sit on a firm surface. Locate pelvic floor muscles. Squeeze and lift muscles around base of penis. Hold for 5 seconds. Release completely.',
 'male', true, ARRAY['testosterone'],
 true, false, false, true, false,
 ARRAY['follicular', 'ovulation', 'luteal']),

-- Female-Specific
('hormonal_postpartum_recovery_kegel', 'Postpartum Recovery Kegels',
 'pelvic_floor', '["core"]'::jsonb, 'body weight', 'waist', 'pelvic_floor',
 1, 'pelvic_floor', 'Lie on your back comfortably. Place pillow under knees. Gently engage pelvic floor (30% effort). Hold for 3-5 seconds. Release slowly.',
 'female', true, ARRAY['fertility', 'estrogen_balance'],
 false, true, true, true, true,
 ARRAY['menstrual', 'follicular', 'luteal']),

('hormonal_vaginal_wall_focus', 'Vaginal Wall Focus',
 'pelvic_floor', '["core"]'::jsonb, 'body weight', 'waist', 'pelvic_floor',
 2, 'pelvic_floor', 'Sit or lie comfortably. Imagine squeezing around the vaginal opening. Draw muscles inward and upward. Hold the squeeze for 5 seconds. Release slowly.',
 'female', true, ARRAY['estrogen_balance', 'menopause', 'fertility'],
 false, true, true, true, true,
 ARRAY['follicular', 'ovulation']),

-- Testosterone-Boosting Compound Movements (explicit)
('hormonal_heavy_compound_squat', 'Heavy Barbell Squat (Testosterone)',
 'quads', '["glutes", "hamstrings", "core", "back"]'::jsonb, 'barbell', 'upper legs', 'quads',
 3, 'strength', 'Set up barbell on shoulders. Feet shoulder-width apart. Brace core and descend. Drive through heels to stand.',
 'all', false, ARRAY['testosterone'],
 true, false, false, false, false,
 ARRAY['follicular', 'ovulation']),

-- PCOS-Friendly
('hormonal_moderate_intensity_walk', 'Moderate Intensity Walking (PCOS)',
 'quads', '["glutes", "hamstrings", "calves"]'::jsonb, 'body weight', 'upper legs', 'cardiovascular system',
 1, 'cardio', 'Walk at a brisk pace. Maintain conversation-friendly intensity. Aim for 20-30 minutes. Can be done outdoors or on treadmill.',
 'all', false, ARRAY['pcos', 'menopause', 'fertility'],
 false, true, true, true, true,
 ARRAY['menstrual', 'follicular', 'ovulation', 'luteal']),

-- Menopause Bone Health
('hormonal_weighted_step_up', 'Weighted Step-Up (Bone Health)',
 'quads', '["glutes", "hamstrings", "calves"]'::jsonb, 'dumbbell', 'upper legs', 'quads',
 2, 'strength', 'Stand facing a sturdy box or step. Hold dumbbells at sides. Step up with one leg. Bring other leg up. Step down with control.',
 'all', false, ARRAY['menopause', 'estrogen_balance'],
 false, true, true, false, false,
 ARRAY['follicular', 'ovulation', 'luteal']),

-- Fertility-Supportive Yoga
('hormonal_legs_up_wall', 'Legs Up the Wall (Fertility)',
 'core', '["hamstrings", "lower_back"]'::jsonb, 'body weight', 'waist', 'abs',
 1, 'flexibility', 'Sit with one hip against wall. Swing legs up the wall as you lie back. Arms out to sides. Relax and breathe for 5-10 minutes.',
 'all', false, ARRAY['fertility', 'menopause'],
 false, true, true, true, true,
 ARRAY['menstrual', 'luteal']),

-- Hormone-Balancing Core Work
('hormonal_diaphragmatic_breathing', 'Diaphragmatic Breathing (Hormone Balance)',
 'core', '["abs"]'::jsonb, 'body weight', 'waist', 'abs',
 1, 'breathing', 'Lie on back with knees bent. Place one hand on chest, one on belly. Breathe in through nose, belly rises. Exhale slowly through mouth. Continue for 5-10 minutes.',
 'all', false, ARRAY['testosterone', 'estrogen_balance', 'pcos', 'menopause', 'fertility'],
 false, true, true, true, true,
 ARRAY['menstrual', 'follicular', 'ovulation', 'luteal'])

ON CONFLICT (external_id) DO UPDATE SET
    target_gender = EXCLUDED.target_gender,
    is_kegel = EXCLUDED.is_kegel,
    hormone_support = EXCLUDED.hormone_support,
    testosterone_boosting = EXCLUDED.testosterone_boosting,
    pcos_friendly = EXCLUDED.pcos_friendly,
    menopause_friendly = EXCLUDED.menopause_friendly,
    fertility_supportive = EXCLUDED.fertility_supportive,
    postpartum_safe = EXCLUDED.postpartum_safe,
    cycle_phase_recommended = EXCLUDED.cycle_phase_recommended;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get exercises filtered by hormonal needs
CREATE OR REPLACE FUNCTION get_hormone_supportive_exercises(
    p_hormone_goals TEXT[],
    p_cycle_phase TEXT DEFAULT NULL,
    p_gender TEXT DEFAULT 'all',
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    exercise_id UUID,
    exercise_name VARCHAR,
    hormone_support TEXT[],
    cycle_phase_recommended TEXT[],
    target_gender VARCHAR(20),
    difficulty_level INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.name,
        e.hormone_support,
        e.cycle_phase_recommended,
        e.target_gender,
        e.difficulty_level
    FROM exercises e
    WHERE
        (
            e.hormone_support && p_hormone_goals
            OR (p_cycle_phase IS NOT NULL AND p_cycle_phase = ANY(e.cycle_phase_recommended))
        )
        AND (
            e.target_gender = 'all'
            OR e.target_gender = p_gender
        )
    ORDER BY
        -- Prioritize exercises that match more goals
        array_length(e.hormone_support, 1) DESC NULLS LAST,
        e.name
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_hormone_supportive_exercises IS 'Get exercises that support specific hormone goals and cycle phases';

-- Function to get kegel exercises by focus area
CREATE OR REPLACE FUNCTION get_kegel_exercises_by_focus(
    p_focus_area TEXT DEFAULT 'general',
    p_difficulty_level INTEGER DEFAULT NULL
)
RETURNS TABLE (
    exercise_id UUID,
    exercise_name VARCHAR,
    instructions TEXT,
    difficulty_level INTEGER,
    target_gender VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.id,
        e.name,
        e.instructions,
        e.difficulty_level,
        e.target_gender
    FROM exercises e
    WHERE
        e.is_kegel = true
        AND (
            p_focus_area = 'general'
            OR (p_focus_area = 'male_specific' AND e.target_gender = 'male')
            OR (p_focus_area = 'female_specific' AND e.target_gender = 'female')
            OR (p_focus_area = 'postpartum' AND e.postpartum_safe = true)
            OR (p_focus_area = 'prostate_health' AND e.name ILIKE '%prostate%')
        )
        AND (
            p_difficulty_level IS NULL
            OR e.difficulty_level = p_difficulty_level
        )
    ORDER BY e.difficulty_level, e.name;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_kegel_exercises_by_focus IS 'Get kegel exercises filtered by focus area and difficulty';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
