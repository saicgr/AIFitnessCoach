-- Flexibility Assessment System Migration
-- Tracks flexibility test results and progress over time
-- Integrates with warmup generation for personalized recommendations

-- ============================================
-- SCHEMA DEFINITIONS
-- ============================================

-- Store flexibility assessment results
CREATE TABLE IF NOT EXISTS flexibility_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    test_type VARCHAR(50) NOT NULL,  -- sit_and_reach, shoulder_flexibility, hip_flexor, etc.
    measurement DECIMAL(8,2) NOT NULL,  -- The measured value
    unit VARCHAR(20) DEFAULT 'inches',
    rating VARCHAR(20),  -- poor, fair, good, excellent
    percentile INT CHECK (percentile >= 0 AND percentile <= 100),
    notes TEXT,
    assessed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Available flexibility tests (reference data)
CREATE TABLE IF NOT EXISTS flexibility_tests (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    instructions JSONB,  -- Array of instruction strings
    unit VARCHAR(20) DEFAULT 'inches',
    target_muscles TEXT[],  -- Array of muscle names
    equipment_needed TEXT[],  -- Array of equipment
    higher_is_better BOOLEAN DEFAULT TRUE,  -- TRUE for most tests, FALSE for gap measurements
    video_url VARCHAR(500),
    image_url VARCHAR(500),
    tips JSONB,  -- Array of tips
    common_mistakes JSONB,  -- Array of common mistakes
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User's recommended stretch routines based on flexibility assessments
CREATE TABLE IF NOT EXISTS flexibility_stretch_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    test_type VARCHAR(50) NOT NULL,
    rating VARCHAR(20) NOT NULL,  -- Based on latest assessment rating
    stretches JSONB NOT NULL,  -- Array of stretch recommendations
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, test_type)
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_flexibility_user ON flexibility_assessments(user_id);
CREATE INDEX IF NOT EXISTS idx_flexibility_type ON flexibility_assessments(test_type);
CREATE INDEX IF NOT EXISTS idx_flexibility_date ON flexibility_assessments(assessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_flexibility_user_type ON flexibility_assessments(user_id, test_type);
CREATE INDEX IF NOT EXISTS idx_flexibility_user_date ON flexibility_assessments(user_id, assessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_flexibility_rating ON flexibility_assessments(rating);

CREATE INDEX IF NOT EXISTS idx_flexibility_tests_active ON flexibility_tests(is_active);
CREATE INDEX IF NOT EXISTS idx_flexibility_tests_muscles ON flexibility_tests USING GIN(target_muscles);

CREATE INDEX IF NOT EXISTS idx_stretch_plans_user ON flexibility_stretch_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_stretch_plans_active ON flexibility_stretch_plans(user_id, is_active);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE flexibility_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE flexibility_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE flexibility_stretch_plans ENABLE ROW LEVEL SECURITY;

-- Users can only view their own flexibility assessments
DROP POLICY IF EXISTS "Users can view own flexibility assessments" ON flexibility_assessments;
CREATE POLICY "Users can view own flexibility assessments"
    ON flexibility_assessments FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own flexibility assessments
DROP POLICY IF EXISTS "Users can insert own flexibility assessments" ON flexibility_assessments;
CREATE POLICY "Users can insert own flexibility assessments"
    ON flexibility_assessments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own flexibility assessments
DROP POLICY IF EXISTS "Users can update own flexibility assessments" ON flexibility_assessments;
CREATE POLICY "Users can update own flexibility assessments"
    ON flexibility_assessments FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own flexibility assessments
DROP POLICY IF EXISTS "Users can delete own flexibility assessments" ON flexibility_assessments;
CREATE POLICY "Users can delete own flexibility assessments"
    ON flexibility_assessments FOR DELETE
    USING (auth.uid() = user_id);

-- Anyone can view flexibility tests (reference data)
DROP POLICY IF EXISTS "Anyone can view flexibility tests" ON flexibility_tests;
CREATE POLICY "Anyone can view flexibility tests"
    ON flexibility_tests FOR SELECT
    USING (true);

-- Users can manage their own stretch plans
DROP POLICY IF EXISTS "Users can manage own stretch plans" ON flexibility_stretch_plans;
CREATE POLICY "Users can manage own stretch plans"
    ON flexibility_stretch_plans FOR ALL
    USING (auth.uid() = user_id);

-- ============================================
-- VIEWS
-- ============================================

-- View for flexibility progress over time
CREATE OR REPLACE VIEW flexibility_progress WITH (security_invoker = true) AS
SELECT
    user_id,
    test_type,
    assessed_at::date as assessment_date,
    measurement,
    unit,
    rating,
    percentile,
    LAG(measurement) OVER (PARTITION BY user_id, test_type ORDER BY assessed_at) as previous_measurement,
    measurement - LAG(measurement) OVER (PARTITION BY user_id, test_type ORDER BY assessed_at) as improvement,
    LAG(rating) OVER (PARTITION BY user_id, test_type ORDER BY assessed_at) as previous_rating,
    ROW_NUMBER() OVER (PARTITION BY user_id, test_type ORDER BY assessed_at) as assessment_number
FROM flexibility_assessments
ORDER BY user_id, test_type, assessed_at;

-- View for latest flexibility assessments per user per test type
CREATE OR REPLACE VIEW latest_flexibility_assessments WITH (security_invoker = true) AS
SELECT DISTINCT ON (user_id, test_type)
    id,
    user_id,
    test_type,
    measurement,
    unit,
    rating,
    percentile,
    notes,
    assessed_at,
    created_at
FROM flexibility_assessments
ORDER BY user_id, test_type, assessed_at DESC;

-- View for flexibility summary per user
CREATE OR REPLACE VIEW flexibility_summary WITH (security_invoker = true) AS
SELECT
    user_id,
    COUNT(DISTINCT test_type) as tests_completed,
    COUNT(*) as total_assessments,
    MIN(assessed_at) as first_assessment,
    MAX(assessed_at) as latest_assessment,
    COUNT(CASE WHEN rating = 'poor' THEN 1 END) as poor_count,
    COUNT(CASE WHEN rating = 'fair' THEN 1 END) as fair_count,
    COUNT(CASE WHEN rating = 'good' THEN 1 END) as good_count,
    COUNT(CASE WHEN rating = 'excellent' THEN 1 END) as excellent_count
FROM flexibility_assessments
GROUP BY user_id;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to get flexibility trend for a user and test type
CREATE OR REPLACE FUNCTION get_flexibility_trend(
    p_user_id UUID,
    p_test_type VARCHAR(50),
    p_days INT DEFAULT 90
)
RETURNS TABLE (
    assessment_date DATE,
    measurement DECIMAL(8,2),
    rating VARCHAR(20),
    improvement DECIMAL(8,2)
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        fa.assessed_at::date,
        fa.measurement,
        fa.rating,
        fa.measurement - LAG(fa.measurement) OVER (ORDER BY fa.assessed_at) as improvement
    FROM flexibility_assessments fa
    WHERE fa.user_id = p_user_id
      AND fa.test_type = p_test_type
      AND fa.assessed_at >= NOW() - (p_days || ' days')::interval
    ORDER BY fa.assessed_at;
END;
$$;

-- Function to get overall flexibility score for a user
CREATE OR REPLACE FUNCTION get_flexibility_score(p_user_id UUID)
RETURNS TABLE (
    overall_score DECIMAL(5,2),
    overall_rating VARCHAR(20),
    tests_completed INT,
    areas_needing_improvement TEXT[]
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_total_score DECIMAL(5,2);
    v_test_count INT;
    v_poor_areas TEXT[];
BEGIN
    -- Calculate score based on latest assessments
    SELECT
        AVG(CASE rating
            WHEN 'poor' THEN 25.0
            WHEN 'fair' THEN 50.0
            WHEN 'good' THEN 75.0
            WHEN 'excellent' THEN 100.0
            ELSE 50.0
        END),
        COUNT(*)
    INTO v_total_score, v_test_count
    FROM latest_flexibility_assessments
    WHERE user_id = p_user_id;

    -- Get areas needing improvement (poor or fair ratings)
    SELECT ARRAY_AGG(test_type)
    INTO v_poor_areas
    FROM latest_flexibility_assessments
    WHERE user_id = p_user_id
      AND rating IN ('poor', 'fair');

    RETURN QUERY SELECT
        COALESCE(v_total_score, 0.0),
        CASE
            WHEN v_total_score >= 75 THEN 'excellent'
            WHEN v_total_score >= 50 THEN 'good'
            WHEN v_total_score >= 25 THEN 'fair'
            ELSE 'poor'
        END,
        COALESCE(v_test_count, 0),
        COALESCE(v_poor_areas, ARRAY[]::TEXT[]);
END;
$$;

-- ============================================
-- SEED DATA: FLEXIBILITY TESTS
-- ============================================

INSERT INTO flexibility_tests (id, name, description, instructions, unit, target_muscles, equipment_needed, higher_is_better, tips, common_mistakes) VALUES
    ('sit_and_reach',
     'Sit and Reach Test',
     'Measures hamstring and lower back flexibility - one of the most common flexibility assessments used worldwide.',
     '["Sit on the floor with legs extended straight in front of you", "Keep your feet flat against a box or wall, about hip-width apart", "Place a ruler or measuring tape along your legs, with the 0 mark at your feet", "Slowly reach forward as far as possible with both hands", "Keep your knees straight - do not bend them", "Hold the maximum reach position for 2 seconds", "Record the distance in inches past (positive) or before (negative) your toes"]',
     'inches',
     ARRAY['hamstrings', 'lower_back', 'calves'],
     ARRAY['ruler or measuring tape', 'sit and reach box (optional)'],
     TRUE,
     '["Warm up with 5-10 minutes of light cardio before testing", "Exhale as you reach forward to allow deeper stretch", "Keep your head neutral - do not strain your neck", "Practice consistently 3-4 times per week for improvement"]',
     '["Bending knees during the reach", "Bouncing to get extra distance", "Not warming up before testing", "Holding breath during the stretch"]'
    ),
    ('shoulder_flexibility',
     'Shoulder Flexibility Test (Apley Scratch Test)',
     'Measures shoulder range of motion and flexibility by testing how close you can bring your hands together behind your back.',
     '["Stand straight with good posture", "Reach one arm over your shoulder (same side as dominant hand first)", "Reach the other arm behind your back, palm facing out", "Try to touch or overlap your fingers", "Measure the gap between fingertips (positive = gap, negative = overlap)", "Test both sides separately and record the average", "Hold for 2 seconds at maximum reach"]',
     'inches',
     ARRAY['shoulders', 'rotator_cuff', 'chest', 'upper_back'],
     ARRAY['ruler or measuring tape', 'partner (helpful but not required)'],
     FALSE,
     '["Warm up shoulders with arm circles before testing", "Do not force the movement - stretch gently", "Test both sides to identify imbalances", "Regular doorway stretches can improve shoulder flexibility"]',
     '["Arching the back to reach further", "Twisting the torso during the test", "Not testing both sides equally", "Rushing the movement instead of controlled reaching"]'
    ),
    ('hip_flexor',
     'Thomas Test (Hip Flexor Flexibility)',
     'Assesses hip flexor tightness by measuring how flat your leg can rest when one knee is pulled to chest.',
     '["Lie on your back at the edge of a table or firm surface", "Pull one knee to your chest and hold it firmly", "Let the other leg hang off the edge naturally", "Measure the angle between the hanging thigh and the table", "A flat thigh (0 degrees) indicates good flexibility", "Record the angle in degrees from horizontal", "Test both legs and note any differences"]',
     'degrees',
     ARRAY['hip_flexors', 'iliopsoas', 'rectus_femoris', 'quadriceps'],
     ARRAY['sturdy table or bench', 'goniometer or protractor (optional)', 'partner (helpful)'],
     FALSE,
     '["Keep the knee of the hanging leg slightly bent", "Do not arch your lower back - keep it flat", "Breathe naturally throughout the test", "Tight hip flexors are common in people who sit a lot"]',
     '["Arching the lower back to compensate", "Not pulling the test knee far enough", "Letting the hanging leg move outward", "Tensing up instead of relaxing"]'
    ),
    ('hamstring',
     'Active Straight Leg Raise (ASLR)',
     'Measures hamstring flexibility by lifting your straight leg while lying on your back.',
     '["Lie flat on your back on a firm surface", "Keep both legs straight and arms by your sides", "Slowly raise one leg as high as possible, keeping it straight", "Keep the other leg flat on the ground", "Measure the angle of the raised leg from the ground", "Hold for 2 seconds at maximum height", "Test both legs and record each angle"]',
     'degrees',
     ARRAY['hamstrings', 'hip_flexors'],
     ARRAY['yoga mat or firm surface', 'goniometer or smartphone angle app (optional)'],
     TRUE,
     '["Keep your lower back pressed into the floor", "Do not bend the knee of the raised leg", "Use controlled movement, not momentum", "Practice hamstring stretches daily for improvement"]',
     '["Bending the knee of the raised leg", "Lifting the non-test leg off the ground", "Arching the lower back", "Using momentum instead of controlled movement"]'
    ),
    ('ankle_dorsiflexion',
     'Ankle Dorsiflexion Test (Knee-to-Wall)',
     'Measures how far your knee can travel past your toes while keeping your heel on the ground.',
     '["Stand facing a wall with one foot about 4 inches from the wall", "Keep your heel firmly on the ground", "Slowly lunge forward, trying to touch your knee to the wall", "If you can touch, move your foot back and try again", "Find the maximum distance where you can still touch the wall", "Measure the distance from your big toe to the wall", "Test both ankles and record separately"]',
     'inches',
     ARRAY['calves', 'achilles_tendon', 'anterior_tibialis'],
     ARRAY['wall', 'ruler or measuring tape'],
     TRUE,
     '["Keep your heel firmly planted - it is the key to accurate testing", "Align your knee over your second toe as you lunge", "Good ankle mobility is crucial for squats and injury prevention", "Calf stretches and foam rolling can improve ankle dorsiflexion"]',
     '["Lifting the heel off the ground", "Letting the knee cave inward", "Not keeping the foot straight", "Moving too quickly"]'
    ),
    ('thoracic_rotation',
     'Thoracic Spine Rotation Test',
     'Measures rotational flexibility of the mid-back, important for sports and daily activities.',
     '["Sit on the floor with legs extended or in a chair", "Cross your arms over your chest, hands on opposite shoulders", "Keep your hips facing forward and stable", "Rotate your upper body as far as possible to one side", "Measure the angle of rotation from the starting position", "Hold for 2 seconds at maximum rotation", "Test both directions and record each measurement"]',
     'degrees',
     ARRAY['thoracic_spine', 'obliques', 'intercostals'],
     ARRAY['chair or floor mat', 'goniometer or protractor (optional)'],
     TRUE,
     '["Keep your hips stable - rotation should come from your mid-back", "Breathe out as you rotate for extra range", "Good thoracic mobility reduces lower back strain", "Practice open book stretches and thoracic extensions"]',
     '["Moving the hips during rotation", "Leaning to one side instead of rotating", "Not keeping arms crossed properly", "Holding breath during the movement"]'
    ),
    ('groin_flexibility',
     'Groin Flexibility Test (Butterfly Stretch)',
     'Measures inner thigh and groin flexibility using the seated butterfly position.',
     '["Sit on the floor with your back straight", "Bring the soles of your feet together", "Pull your feet as close to your body as comfortable", "Let your knees fall outward toward the floor", "Measure the distance from each knee to the floor", "Record the average of both sides in inches", "Hold the position for 2-3 seconds while measuring"]',
     'inches',
     ARRAY['adductors', 'hip_flexors', 'inner_thighs'],
     ARRAY['yoga mat or floor', 'ruler or measuring tape'],
     FALSE,
     '["Sit on a cushion if you have lower back discomfort", "Do not force your knees down - let gravity do the work", "Lean slightly forward from the hips for a deeper stretch", "Practice daily for gradual improvement"]',
     '["Pressing down on knees with hands", "Rounding the lower back", "Holding breath during the stretch", "Bouncing to try to get lower"]'
    ),
    ('quadriceps',
     'Quadriceps Flexibility Test (Prone Heel to Buttock)',
     'Measures quadriceps and hip flexor flexibility by seeing how close your heel can reach your buttock.',
     '["Lie face down on a flat surface", "Bend one knee and bring your heel toward your buttock", "Use your hand to gently assist if needed", "Measure the distance between your heel and buttock", "Keep your hips flat on the ground - do not let them rise", "Hold for 2 seconds at maximum stretch", "Test both legs and record each measurement"]',
     'inches',
     ARRAY['quadriceps', 'hip_flexors'],
     ARRAY['yoga mat or firm surface', 'ruler or measuring tape'],
     FALSE,
     '["Keep your hips pressed into the floor throughout", "Do not force the stretch - go to comfortable tension", "Tight quads are common in runners and cyclists", "Foam rolling before stretching can help"]',
     '["Lifting hips off the ground", "Rotating the hip outward", "Pulling too aggressively on the foot", "Arching the lower back"]'
    ),
    ('calf_flexibility',
     'Calf Flexibility Test (Standing Wall Stretch)',
     'Measures gastrocnemius (calf) flexibility using a wall stretch position.',
     '["Stand facing a wall, about arm length away", "Place both hands on the wall at shoulder height", "Step one foot back, keeping it straight", "Lean into the wall, keeping the back heel on the ground", "Measure the distance from your back heel to the wall", "Find the maximum distance while keeping heel down", "Test both legs and record each measurement"]',
     'inches',
     ARRAY['gastrocnemius', 'soleus', 'achilles_tendon'],
     ARRAY['wall', 'ruler or measuring tape'],
     TRUE,
     '["Keep your back leg completely straight", "Point your toes forward, not outward", "Lean your hips toward the wall, not just your upper body", "Calf stretches are essential for runners and walkers"]',
     '["Bending the back knee", "Lifting the heel off the ground", "Turning the back foot outward", "Leaning only from the upper body"]'
    ),
    ('neck_rotation',
     'Neck Rotation Test',
     'Measures cervical spine rotation - how far you can turn your head to each side.',
     '["Sit or stand with good posture, looking straight ahead", "Slowly rotate your head to one side as far as comfortable", "Keep your chin level - do not tilt up or down", "Your shoulders should remain still and facing forward", "Measure the angle of rotation from center", "Hold for 2 seconds at maximum rotation", "Test both sides and record each measurement"]',
     'degrees',
     ARRAY['neck_rotators', 'sternocleidomastoid', 'upper_trapezius'],
     ARRAY['goniometer or smartphone angle app (optional)'],
     TRUE,
     '["Move slowly and smoothly - never force the movement", "Keep your shoulders relaxed", "Good neck mobility helps prevent tension headaches", "Regular neck stretches are important for desk workers"]',
     '["Tilting the head while rotating", "Moving the shoulders", "Rotating too quickly", "Holding breath during the movement"]'
    )
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    instructions = EXCLUDED.instructions,
    unit = EXCLUDED.unit,
    target_muscles = EXCLUDED.target_muscles,
    equipment_needed = EXCLUDED.equipment_needed,
    higher_is_better = EXCLUDED.higher_is_better,
    tips = EXCLUDED.tips,
    common_mistakes = EXCLUDED.common_mistakes;

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE flexibility_assessments IS 'Stores flexibility test results for tracking progress over time';
COMMENT ON TABLE flexibility_tests IS 'Reference table containing all available flexibility tests with instructions and norms';
COMMENT ON TABLE flexibility_stretch_plans IS 'Personalized stretch recommendations based on flexibility assessment results';

COMMENT ON COLUMN flexibility_assessments.test_type IS 'The type of flexibility test (e.g., sit_and_reach, shoulder_flexibility)';
COMMENT ON COLUMN flexibility_assessments.measurement IS 'The measured value in the appropriate unit for the test';
COMMENT ON COLUMN flexibility_assessments.rating IS 'The rating based on age and gender norms: poor, fair, good, excellent';
COMMENT ON COLUMN flexibility_assessments.percentile IS 'The percentile ranking compared to population norms (0-100)';

COMMENT ON COLUMN flexibility_tests.higher_is_better IS 'TRUE for tests where higher values are better, FALSE for gap/angle tests where lower is better';
COMMENT ON COLUMN flexibility_tests.target_muscles IS 'Array of muscle groups targeted by this flexibility test';

COMMENT ON VIEW flexibility_progress IS 'Shows flexibility progress over time with improvement calculations';
COMMENT ON VIEW latest_flexibility_assessments IS 'Returns only the most recent assessment for each test type per user';
COMMENT ON VIEW flexibility_summary IS 'Aggregated statistics for each user flexibility assessments';

COMMENT ON FUNCTION get_flexibility_trend IS 'Returns flexibility trend data for a specific test over a given number of days';
COMMENT ON FUNCTION get_flexibility_score IS 'Calculates overall flexibility score and identifies areas needing improvement';
