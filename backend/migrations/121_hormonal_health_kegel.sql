-- Migration 121: Hormonal Health & Kegel/Pelvic Floor System
-- Description: Comprehensive hormonal health tracking for testosterone optimization,
--              estrogen balance, menstrual cycle tracking, and pelvic floor exercises
-- Date: 2025-01-01

-- ============================================================================
-- HORMONAL PROFILES TABLE
-- Stores user's hormonal health settings and goals
-- ============================================================================
CREATE TABLE IF NOT EXISTS hormonal_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Gender/Sex Information
    gender TEXT CHECK (gender IN ('male', 'female', 'non_binary', 'other', 'prefer_not_to_say')),
    birth_sex TEXT CHECK (birth_sex IN ('male', 'female', 'intersex', 'prefer_not_to_say')),

    -- Hormone Optimization Goals (array for multi-select)
    hormone_goals TEXT[] DEFAULT '{}' CHECK (
        hormone_goals <@ ARRAY[
            'optimize_testosterone',
            'balance_estrogen',
            'improve_fertility',
            'menopause_support',
            'pcos_management',
            'perimenopause_support',
            'andropause_support',
            'general_wellness',
            'libido_enhancement',
            'energy_optimization',
            'mood_stabilization',
            'sleep_improvement'
        ]::TEXT[]
    ),

    -- Menstrual Cycle Tracking
    menstrual_tracking_enabled BOOLEAN DEFAULT false,
    cycle_length_days INTEGER CHECK (cycle_length_days IS NULL OR (cycle_length_days >= 21 AND cycle_length_days <= 45)),
    last_period_start_date DATE,
    typical_period_duration_days INTEGER CHECK (typical_period_duration_days IS NULL OR (typical_period_duration_days >= 2 AND typical_period_duration_days <= 10)),
    cycle_regularity TEXT CHECK (cycle_regularity IN ('regular', 'irregular', 'very_irregular', 'unknown')),

    -- Menopause/Andropause Status
    menopause_status TEXT CHECK (menopause_status IN ('pre', 'peri', 'post', 'not_applicable')) DEFAULT 'not_applicable',
    andropause_status TEXT CHECK (andropause_status IN ('none', 'early', 'moderate', 'advanced', 'not_applicable')) DEFAULT 'not_applicable',

    -- Feature Toggles
    testosterone_optimization_enabled BOOLEAN DEFAULT false,
    estrogen_balance_enabled BOOLEAN DEFAULT false,
    include_hormone_supportive_foods BOOLEAN DEFAULT true,
    include_hormone_supportive_exercises BOOLEAN DEFAULT true,
    cycle_sync_workouts BOOLEAN DEFAULT false,  -- Adjust workout intensity based on cycle phase
    cycle_sync_nutrition BOOLEAN DEFAULT false, -- Adjust nutrition based on cycle phase

    -- Health Conditions
    has_pcos BOOLEAN DEFAULT false,
    has_endometriosis BOOLEAN DEFAULT false,
    has_thyroid_condition BOOLEAN DEFAULT false,
    thyroid_condition_type TEXT CHECK (thyroid_condition_type IN ('hypothyroid', 'hyperthyroid', 'hashimotos', 'graves', 'other', NULL)),
    on_hormone_therapy BOOLEAN DEFAULT false,
    hormone_therapy_type TEXT,  -- e.g., 'HRT', 'TRT', 'Birth Control', etc.

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure one profile per user
    CONSTRAINT unique_user_hormonal_profile UNIQUE (user_id)
);

COMMENT ON TABLE hormonal_profiles IS 'User hormonal health profiles for personalized hormone optimization';
COMMENT ON COLUMN hormonal_profiles.hormone_goals IS 'Multi-select hormone optimization goals';
COMMENT ON COLUMN hormonal_profiles.cycle_sync_workouts IS 'When enabled, workout intensity adjusts based on menstrual cycle phase';

-- ============================================================================
-- HORMONE LOGS TABLE
-- Daily hormone-related symptom and wellness tracking
-- ============================================================================
CREATE TABLE IF NOT EXISTS hormone_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,

    -- Cycle Information (for menstrual tracking)
    cycle_day INTEGER CHECK (cycle_day IS NULL OR (cycle_day >= 1 AND cycle_day <= 45)),
    cycle_phase TEXT CHECK (cycle_phase IN ('menstrual', 'follicular', 'ovulation', 'luteal', NULL)),
    period_flow TEXT CHECK (period_flow IN ('none', 'spotting', 'light', 'medium', 'heavy', NULL)),

    -- Wellness Metrics (1-10 scale)
    energy_level INTEGER CHECK (energy_level IS NULL OR (energy_level >= 1 AND energy_level <= 10)),
    sleep_quality INTEGER CHECK (sleep_quality IS NULL OR (sleep_quality >= 1 AND sleep_quality <= 10)),
    libido_level INTEGER CHECK (libido_level IS NULL OR (libido_level >= 1 AND libido_level <= 10)),
    stress_level INTEGER CHECK (stress_level IS NULL OR (stress_level >= 1 AND stress_level <= 10)),
    motivation_level INTEGER CHECK (motivation_level IS NULL OR (motivation_level >= 1 AND motivation_level <= 10)),
    recovery_feeling INTEGER CHECK (recovery_feeling IS NULL OR (recovery_feeling >= 1 AND recovery_feeling <= 10)),

    -- Mood Tracking
    mood TEXT CHECK (mood IN ('excellent', 'good', 'stable', 'low', 'irritable', 'anxious', 'depressed', NULL)),
    mood_notes TEXT,

    -- Physical Symptoms (array for multi-select)
    symptoms TEXT[] DEFAULT '{}' CHECK (
        symptoms <@ ARRAY[
            'bloating', 'cramps', 'headache', 'migraine', 'hot_flashes', 'night_sweats',
            'fatigue', 'muscle_weakness', 'brain_fog', 'breast_tenderness',
            'back_pain', 'joint_pain', 'acne', 'skin_changes', 'hair_changes',
            'weight_fluctuation', 'water_retention', 'digestive_issues',
            'insomnia', 'vivid_dreams', 'anxiety', 'irritability',
            'low_libido', 'vaginal_dryness', 'erectile_difficulty'
        ]::TEXT[]
    ),

    -- Additional Tracking
    exercise_performed BOOLEAN,
    exercise_intensity TEXT CHECK (exercise_intensity IN ('rest', 'light', 'moderate', 'intense', NULL)),
    basal_body_temperature DECIMAL(4,2),  -- For fertility tracking
    cervical_mucus TEXT CHECK (cervical_mucus IN ('dry', 'sticky', 'creamy', 'watery', 'egg_white', NULL)),

    -- Notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- One log per user per day
    CONSTRAINT unique_daily_hormone_log UNIQUE (user_id, log_date)
);

COMMENT ON TABLE hormone_logs IS 'Daily hormone-related symptom and wellness tracking';
COMMENT ON COLUMN hormone_logs.basal_body_temperature IS 'BBT for fertility tracking (Celsius)';

-- ============================================================================
-- KEGEL PREFERENCES TABLE
-- User preferences for pelvic floor exercise inclusion
-- ============================================================================
CREATE TABLE IF NOT EXISTS kegel_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Main Toggle
    kegels_enabled BOOLEAN DEFAULT false,

    -- Placement Options
    include_in_warmup BOOLEAN DEFAULT false,
    include_in_cooldown BOOLEAN DEFAULT false,
    include_as_standalone BOOLEAN DEFAULT false,  -- Separate pelvic floor workouts
    include_in_daily_routine BOOLEAN DEFAULT false,  -- Quick daily exercises

    -- Reminder Settings
    daily_reminder_enabled BOOLEAN DEFAULT false,
    daily_reminder_time TIME,
    reminder_frequency TEXT CHECK (reminder_frequency IN ('once', 'twice', 'three_times', 'hourly')) DEFAULT 'twice',

    -- Goals
    target_sessions_per_day INTEGER DEFAULT 3 CHECK (target_sessions_per_day >= 1 AND target_sessions_per_day <= 10),
    target_duration_seconds INTEGER DEFAULT 300,  -- 5 minutes default

    -- Progression Level
    current_level TEXT CHECK (current_level IN ('beginner', 'intermediate', 'advanced')) DEFAULT 'beginner',

    -- Gender-specific focus
    focus_area TEXT CHECK (focus_area IN ('general', 'male_specific', 'female_specific', 'postpartum', 'prostate_health')) DEFAULT 'general',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT unique_user_kegel_preferences UNIQUE (user_id)
);

COMMENT ON TABLE kegel_preferences IS 'User preferences for pelvic floor/kegel exercise inclusion in workouts';

-- ============================================================================
-- KEGEL SESSIONS TABLE
-- Track completed kegel exercise sessions
-- ============================================================================
CREATE TABLE IF NOT EXISTS kegel_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    session_time TIME DEFAULT CURRENT_TIME,

    -- Session Details
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    reps_completed INTEGER CHECK (reps_completed >= 0),
    hold_duration_seconds INTEGER CHECK (hold_duration_seconds >= 0),

    -- Session Type
    session_type TEXT CHECK (session_type IN ('quick', 'standard', 'advanced', 'custom')) DEFAULT 'standard',
    exercise_name TEXT,  -- Specific exercise performed

    -- Context
    performed_during TEXT CHECK (performed_during IN ('warmup', 'cooldown', 'standalone', 'daily_routine', 'other')),
    workout_id UUID,  -- Link to workout if performed during workout

    -- Feedback
    difficulty_rating INTEGER CHECK (difficulty_rating IS NULL OR (difficulty_rating >= 1 AND difficulty_rating <= 5)),
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE kegel_sessions IS 'Completed pelvic floor exercise sessions';

-- ============================================================================
-- KEGEL EXERCISES REFERENCE TABLE
-- Master list of pelvic floor exercises
-- ============================================================================
CREATE TABLE IF NOT EXISTS kegel_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT[] NOT NULL,  -- Step-by-step instructions

    -- Targeting
    target_audience TEXT CHECK (target_audience IN ('all', 'male', 'female')) DEFAULT 'all',
    focus_muscles TEXT[] DEFAULT '{}',  -- e.g., 'pubococcygeus', 'levator ani'

    -- Difficulty & Duration
    difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')) DEFAULT 'beginner',
    default_duration_seconds INTEGER DEFAULT 30,
    default_reps INTEGER DEFAULT 10,
    default_hold_seconds INTEGER DEFAULT 5,
    rest_between_reps_seconds INTEGER DEFAULT 5,

    -- Benefits
    benefits TEXT[] DEFAULT '{}',

    -- Metadata
    video_url TEXT,
    animation_type TEXT,  -- For in-app animations
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE kegel_exercises IS 'Reference table of pelvic floor exercises with instructions';

-- ============================================================================
-- HORMONE-SUPPORTIVE FOODS REFERENCE TABLE
-- Foods that support hormonal health
-- ============================================================================
CREATE TABLE IF NOT EXISTS hormone_supportive_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,  -- e.g., 'protein', 'vegetable', 'fat', 'seed'

    -- Hormone Support Categories
    supports_testosterone BOOLEAN DEFAULT false,
    supports_estrogen_balance BOOLEAN DEFAULT false,
    supports_pcos BOOLEAN DEFAULT false,
    supports_menopause BOOLEAN DEFAULT false,
    supports_fertility BOOLEAN DEFAULT false,
    supports_thyroid BOOLEAN DEFAULT false,

    -- Cycle Phase Recommendations
    good_for_menstrual BOOLEAN DEFAULT false,
    good_for_follicular BOOLEAN DEFAULT false,
    good_for_ovulation BOOLEAN DEFAULT false,
    good_for_luteal BOOLEAN DEFAULT false,

    -- Key Nutrients
    key_nutrients TEXT[] DEFAULT '{}',  -- e.g., 'zinc', 'vitamin_d', 'omega3'

    -- Notes
    description TEXT,
    serving_suggestion TEXT,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE hormone_supportive_foods IS 'Reference table of hormone-supportive foods for dietary recommendations';

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_hormonal_profiles_user_id ON hormonal_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_hormone_logs_user_date ON hormone_logs(user_id, log_date DESC);
CREATE INDEX IF NOT EXISTS idx_hormone_logs_cycle_phase ON hormone_logs(user_id, cycle_phase) WHERE cycle_phase IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_kegel_preferences_user_id ON kegel_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_kegel_sessions_user_date ON kegel_sessions(user_id, session_date DESC);
CREATE INDEX IF NOT EXISTS idx_kegel_sessions_workout ON kegel_sessions(workout_id) WHERE workout_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_kegel_exercises_audience ON kegel_exercises(target_audience, difficulty);
CREATE INDEX IF NOT EXISTS idx_hormone_foods_testosterone ON hormone_supportive_foods(supports_testosterone) WHERE supports_testosterone = true;
CREATE INDEX IF NOT EXISTS idx_hormone_foods_estrogen ON hormone_supportive_foods(supports_estrogen_balance) WHERE supports_estrogen_balance = true;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE hormonal_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE hormone_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE kegel_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE kegel_sessions ENABLE ROW LEVEL SECURITY;

-- Hormonal Profiles Policies
CREATE POLICY "Users can view own hormonal profile"
    ON hormonal_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own hormonal profile"
    ON hormonal_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own hormonal profile"
    ON hormonal_profiles FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own hormonal profile"
    ON hormonal_profiles FOR DELETE
    USING (auth.uid() = user_id);

-- Hormone Logs Policies
CREATE POLICY "Users can view own hormone logs"
    ON hormone_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own hormone logs"
    ON hormone_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own hormone logs"
    ON hormone_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own hormone logs"
    ON hormone_logs FOR DELETE
    USING (auth.uid() = user_id);

-- Kegel Preferences Policies
CREATE POLICY "Users can view own kegel preferences"
    ON kegel_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own kegel preferences"
    ON kegel_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own kegel preferences"
    ON kegel_preferences FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own kegel preferences"
    ON kegel_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- Kegel Sessions Policies
CREATE POLICY "Users can view own kegel sessions"
    ON kegel_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own kegel sessions"
    ON kegel_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own kegel sessions"
    ON kegel_sessions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own kegel sessions"
    ON kegel_sessions FOR DELETE
    USING (auth.uid() = user_id);

-- Reference tables are public read
CREATE POLICY "Anyone can view kegel exercises"
    ON kegel_exercises FOR SELECT
    USING (true);

CREATE POLICY "Anyone can view hormone supportive foods"
    ON hormone_supportive_foods FOR SELECT
    USING (true);

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================
CREATE OR REPLACE FUNCTION update_hormonal_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_hormonal_profiles_updated_at
    BEFORE UPDATE ON hormonal_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_hormonal_updated_at();

CREATE TRIGGER trigger_kegel_preferences_updated_at
    BEFORE UPDATE ON kegel_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_hormonal_updated_at();

-- ============================================================================
-- SEED DATA: KEGEL EXERCISES
-- ============================================================================
INSERT INTO kegel_exercises (name, display_name, description, instructions, target_audience, difficulty, default_duration_seconds, default_reps, default_hold_seconds, rest_between_reps_seconds, benefits, focus_muscles, sort_order) VALUES

-- Beginner Exercises (All Genders)
('basic_kegel_hold', 'Basic Kegel Hold',
 'The foundational pelvic floor exercise. Squeeze and hold the muscles you would use to stop urinating.',
 ARRAY['Sit or lie down comfortably', 'Identify your pelvic floor muscles (imagine stopping urine flow)', 'Squeeze these muscles and hold', 'Release and relax completely', 'Repeat'],
 'all', 'beginner', 60, 10, 5, 5,
 ARRAY['Strengthens pelvic floor', 'Improves bladder control', 'Enhances core stability'],
 ARRAY['pubococcygeus', 'levator ani'], 1),

('quick_flicks', 'Quick Flicks',
 'Rapid contractions to build fast-twitch muscle response in the pelvic floor.',
 ARRAY['Get into a comfortable position', 'Quickly squeeze your pelvic floor muscles', 'Immediately release', 'Repeat rapidly without holding', 'Focus on the squeeze-release rhythm'],
 'all', 'beginner', 60, 20, 1, 1,
 ARRAY['Builds fast-twitch response', 'Improves reaction time', 'Helps prevent stress incontinence'],
 ARRAY['pubococcygeus'], 2),

('breathing_kegels', 'Breathing Kegels',
 'Coordinate pelvic floor contractions with breath for deeper engagement.',
 ARRAY['Lie on your back with knees bent', 'Inhale deeply, relaxing the pelvic floor', 'As you exhale, squeeze the pelvic floor', 'Hold the squeeze through the exhale', 'Inhale and release', 'Repeat with each breath cycle'],
 'all', 'beginner', 120, 10, 4, 6,
 ARRAY['Improves mind-muscle connection', 'Enhances core coordination', 'Reduces tension'],
 ARRAY['pubococcygeus', 'diaphragm'], 3),

-- Intermediate Exercises
('elevator_kegels', 'Elevator Kegels',
 'Progressive contraction exercise where you gradually increase tension like going up floors in an elevator.',
 ARRAY['Visualize your pelvic floor as an elevator', 'Start with a light squeeze (floor 1)', 'Gradually increase to medium (floor 2)', 'Then to strong squeeze (floor 3)', 'Hold at the top briefly', 'Slowly release back down floor by floor', 'Relax completely at the bottom'],
 'all', 'intermediate', 90, 5, 10, 10,
 ARRAY['Builds progressive strength', 'Improves muscle control', 'Enhances awareness of muscle tension levels'],
 ARRAY['pubococcygeus', 'levator ani'], 4),

('bridge_with_kegel', 'Bridge with Kegel',
 'Combine a glute bridge with pelvic floor engagement for functional strength.',
 ARRAY['Lie on your back, knees bent, feet flat', 'Arms at your sides', 'Squeeze your pelvic floor muscles', 'While holding, lift your hips into a bridge', 'Hold the bridge and kegel together', 'Lower your hips while maintaining the squeeze', 'Release the kegel at the bottom', 'Rest and repeat'],
 'all', 'intermediate', 120, 12, 5, 5,
 ARRAY['Functional pelvic-glute integration', 'Strengthens posterior chain', 'Improves hip stability'],
 ARRAY['pubococcygeus', 'gluteus maximus'], 5),

('wall_sit_kegels', 'Wall Sit Kegels',
 'Perform kegels while in a wall sit position for added core challenge.',
 ARRAY['Stand with your back against a wall', 'Slide down into a seated position (thighs parallel to floor)', 'Hold the wall sit position', 'Perform kegel squeezes while holding', 'Squeeze for 5 seconds, release for 5 seconds', 'Continue for the duration', 'Stand up to rest between sets'],
 'all', 'intermediate', 60, 8, 5, 5,
 ARRAY['Builds endurance', 'Challenges core stability', 'Functional strength integration'],
 ARRAY['pubococcygeus', 'quadriceps', 'core'], 6),

-- Advanced Exercises
('pulse_and_hold', 'Pulse and Hold',
 'Combine quick pulses with sustained holds for comprehensive training.',
 ARRAY['Perform 5 quick kegel pulses', 'On the 5th pulse, hold for 10 seconds', 'Release and rest for 5 seconds', 'Repeat the pulse-hold sequence', 'Focus on maintaining strong contractions throughout'],
 'all', 'advanced', 120, 6, 10, 5,
 ARRAY['Trains both fast and slow twitch fibers', 'Maximum muscle fatigue', 'Advanced muscle control'],
 ARRAY['pubococcygeus', 'levator ani'], 7),

('squat_kegels', 'Deep Squat Kegels',
 'Perform kegels in a deep squat position for maximum pelvic floor engagement.',
 ARRAY['Stand with feet shoulder-width apart', 'Lower into a deep squat (as low as comfortable)', 'Hold the squat position', 'Perform kegel contractions in this position', 'Squeeze and hold for 5 seconds', 'Release for 3 seconds', 'Continue for duration', 'Stand up to rest'],
 'all', 'advanced', 90, 10, 5, 3,
 ARRAY['Maximum pelvic floor stretch', 'Functional strength', 'Hip mobility integration'],
 ARRAY['pubococcygeus', 'hip flexors', 'glutes'], 8),

-- Female-Specific
('postpartum_recovery', 'Postpartum Recovery Kegels',
 'Gentle pelvic floor restoration designed for postpartum recovery.',
 ARRAY['Lie on your back in a comfortable position', 'Place a pillow under your knees if needed', 'Take several deep breaths to relax', 'Gently engage your pelvic floor (about 30% effort)', 'Hold for 3-5 seconds', 'Release slowly and completely', 'Rest for 10 seconds between reps', 'Stop if you feel any pain'],
 'female', 'beginner', 180, 8, 4, 10,
 ARRAY['Gentle recovery', 'Restores pelvic floor tone', 'Safe for early postpartum'],
 ARRAY['pubococcygeus'], 9),

('vaginal_tightening', 'Vaginal Wall Focus',
 'Targeted exercise focusing on the vaginal wall muscles.',
 ARRAY['Sit or lie comfortably', 'Imagine squeezing around the vaginal opening', 'Draw the muscles inward and upward', 'Hold the squeeze', 'Release slowly', 'Rest and repeat'],
 'female', 'intermediate', 90, 12, 5, 5,
 ARRAY['Vaginal muscle tone', 'Sexual health benefits', 'Bladder support'],
 ARRAY['pubococcygeus', 'vaginal wall muscles'], 10),

-- Male-Specific
('prostate_support', 'Prostate Support Kegels',
 'Targeted pelvic floor exercise for prostate health and urinary control.',
 ARRAY['Sit on a firm surface', 'Locate your pelvic floor muscles (imagine stopping urination)', 'Squeeze and lift the muscles around the base of the penis', 'Focus on drawing inward, not pushing', 'Hold for 5 seconds', 'Release completely for 5 seconds', 'Repeat'],
 'male', 'beginner', 90, 10, 5, 5,
 ARRAY['Prostate health support', 'Urinary control', 'Post-prostatectomy recovery'],
 ARRAY['pubococcygeus', 'bulbocavernosus'], 11),

('reverse_kegel', 'Reverse Kegel (Relaxation)',
 'Learn to consciously relax the pelvic floor - important for balance.',
 ARRAY['Find a comfortable seated or lying position', 'Take a deep breath in', 'As you exhale, consciously relax and release your pelvic floor', 'Imagine the muscles dropping and opening', 'Feel the release without pushing or bearing down', 'Hold the relaxed state for 5 seconds', 'Gently contract back to neutral', 'Repeat'],
 'all', 'intermediate', 90, 8, 5, 5,
 ARRAY['Prevents over-tightening', 'Balances pelvic floor function', 'Reduces pelvic tension'],
 ARRAY['pubococcygeus', 'levator ani'], 12)

ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    instructions = EXCLUDED.instructions,
    target_audience = EXCLUDED.target_audience,
    difficulty = EXCLUDED.difficulty,
    default_duration_seconds = EXCLUDED.default_duration_seconds,
    default_reps = EXCLUDED.default_reps,
    default_hold_seconds = EXCLUDED.default_hold_seconds,
    rest_between_reps_seconds = EXCLUDED.rest_between_reps_seconds,
    benefits = EXCLUDED.benefits,
    focus_muscles = EXCLUDED.focus_muscles,
    sort_order = EXCLUDED.sort_order;

-- ============================================================================
-- SEED DATA: HORMONE-SUPPORTIVE FOODS
-- ============================================================================
INSERT INTO hormone_supportive_foods (name, category, supports_testosterone, supports_estrogen_balance, supports_pcos, supports_menopause, supports_fertility, supports_thyroid, good_for_menstrual, good_for_follicular, good_for_ovulation, good_for_luteal, key_nutrients, description) VALUES

-- Testosterone-Supporting Foods
('Oysters', 'seafood', true, false, false, false, true, false, false, false, false, false,
 ARRAY['zinc', 'vitamin_d', 'b12', 'selenium'], 'Highest natural source of zinc, essential for testosterone production'),
('Eggs', 'protein', true, false, false, false, true, false, true, true, true, true,
 ARRAY['cholesterol', 'vitamin_d', 'protein', 'choline'], 'Contains cholesterol needed for hormone synthesis'),
('Beef (Grass-fed)', 'protein', true, false, false, false, false, false, true, false, false, false,
 ARRAY['zinc', 'iron', 'b12', 'protein'], 'Rich in zinc and saturated fats for hormone production'),
('Tuna', 'seafood', true, false, false, false, true, false, false, true, false, false,
 ARRAY['vitamin_d', 'omega3', 'protein', 'selenium'], 'Excellent source of vitamin D linked to testosterone'),
('Pomegranate', 'fruit', true, true, true, false, false, false, false, true, true, false,
 ARRAY['antioxidants', 'nitrates', 'vitamin_c'], 'May increase testosterone and improve blood flow'),
('Garlic', 'vegetable', true, true, true, false, false, false, false, true, true, true,
 ARRAY['allicin', 'selenium', 'vitamin_c'], 'Contains allicin which may support testosterone'),
('Ginger', 'spice', true, false, true, false, true, false, true, false, false, true,
 ARRAY['gingerol', 'antioxidants'], 'Anti-inflammatory, may boost testosterone'),

-- Estrogen-Balancing Foods
('Flaxseeds', 'seed', false, true, true, true, true, false, true, true, false, true,
 ARRAY['lignans', 'omega3', 'fiber'], 'Lignans help balance estrogen levels'),
('Cruciferous Vegetables', 'vegetable', false, true, true, true, false, true, false, true, true, false,
 ARRAY['indole_3_carbinol', 'fiber', 'vitamin_c'], 'Broccoli, cauliflower, kale - help metabolize estrogen'),
('Berries', 'fruit', false, true, true, true, true, false, true, true, true, true,
 ARRAY['antioxidants', 'fiber', 'vitamin_c'], 'Antioxidants support hormone balance'),
('Turmeric', 'spice', false, true, true, true, false, false, true, false, false, true,
 ARRAY['curcumin', 'antioxidants'], 'Anti-inflammatory, supports estrogen metabolism'),

-- PCOS-Supportive Foods
('Salmon', 'seafood', true, true, true, true, true, true, true, true, true, true,
 ARRAY['omega3', 'vitamin_d', 'protein', 'selenium'], 'Omega-3s reduce inflammation in PCOS'),
('Avocado', 'fruit', true, true, true, true, true, false, false, true, true, true,
 ARRAY['healthy_fats', 'fiber', 'potassium', 'vitamin_e'], 'Healthy fats support hormone production'),
('Leafy Greens', 'vegetable', false, true, true, true, true, true, true, true, true, true,
 ARRAY['folate', 'iron', 'magnesium', 'fiber'], 'Spinach, kale - essential for hormone health'),
('Nuts (Almonds, Walnuts)', 'nut', true, true, true, true, true, true, false, true, true, true,
 ARRAY['healthy_fats', 'magnesium', 'zinc', 'vitamin_e'], 'Support hormone production and reduce inflammation'),
('Olive Oil', 'fat', true, true, true, true, true, false, false, true, true, true,
 ARRAY['monounsaturated_fats', 'antioxidants', 'vitamin_e'], 'Anti-inflammatory healthy fat'),
('Cinnamon', 'spice', false, false, true, false, false, false, false, true, false, true,
 ARRAY['cinnamaldehyde', 'antioxidants'], 'May improve insulin sensitivity in PCOS'),

-- Menopause-Supportive Foods
('Soy (Moderate)', 'legume', false, true, false, true, false, true, false, false, false, true,
 ARRAY['phytoestrogens', 'protein', 'calcium'], 'Phytoestrogens may help with hot flashes'),
('Chickpeas', 'legume', false, true, true, true, true, false, false, true, true, true,
 ARRAY['phytoestrogens', 'fiber', 'protein'], 'Plant-based phytoestrogens'),
('Whole Grains', 'grain', false, true, true, true, true, true, true, true, true, true,
 ARRAY['fiber', 'b_vitamins', 'magnesium'], 'Support stable blood sugar and hormone balance'),

-- Fertility-Supportive Foods
('Spinach', 'vegetable', false, true, true, true, true, true, true, true, true, true,
 ARRAY['folate', 'iron', 'magnesium', 'vitamin_k'], 'Essential folate for fertility'),
('Citrus Fruits', 'fruit', false, false, false, false, true, false, false, true, true, false,
 ARRAY['vitamin_c', 'folate', 'antioxidants'], 'Vitamin C supports reproductive health'),
('Sweet Potatoes', 'vegetable', false, false, true, true, true, false, false, true, false, true,
 ARRAY['beta_carotene', 'vitamin_a', 'fiber'], 'Beta-carotene may support ovulation'),

-- Thyroid-Supportive Foods
('Brazil Nuts', 'nut', true, false, false, false, true, true, false, true, false, false,
 ARRAY['selenium', 'healthy_fats'], 'Selenium essential for thyroid function'),
('Seaweed', 'vegetable', false, false, false, false, false, true, false, true, false, false,
 ARRAY['iodine', 'selenium', 'minerals'], 'Natural iodine source for thyroid'),

-- Cycle Phase-Specific
('Dark Chocolate', 'treat', false, true, true, false, false, false, true, false, false, true,
 ARRAY['magnesium', 'iron', 'antioxidants'], 'Magnesium helps with menstrual cramps'),
('Lentils', 'legume', false, true, true, true, true, false, true, true, false, true,
 ARRAY['iron', 'protein', 'fiber', 'folate'], 'Iron replenishment during menstruation'),
('Pumpkin Seeds', 'seed', true, true, true, false, true, false, false, false, true, true,
 ARRAY['zinc', 'magnesium', 'omega3'], 'Zinc and magnesium for ovulation and luteal support')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View for user's current cycle phase
CREATE OR REPLACE VIEW user_current_cycle_phase AS
SELECT
    hp.user_id,
    hp.menstrual_tracking_enabled,
    hp.last_period_start_date,
    hp.cycle_length_days,
    CASE
        WHEN hp.menstrual_tracking_enabled = false THEN NULL
        WHEN hp.last_period_start_date IS NULL THEN NULL
        ELSE (CURRENT_DATE - hp.last_period_start_date) % COALESCE(hp.cycle_length_days, 28) + 1
    END as current_cycle_day,
    CASE
        WHEN hp.menstrual_tracking_enabled = false THEN NULL
        WHEN hp.last_period_start_date IS NULL THEN NULL
        WHEN (CURRENT_DATE - hp.last_period_start_date) % COALESCE(hp.cycle_length_days, 28) + 1 <= 5 THEN 'menstrual'
        WHEN (CURRENT_DATE - hp.last_period_start_date) % COALESCE(hp.cycle_length_days, 28) + 1 <= 13 THEN 'follicular'
        WHEN (CURRENT_DATE - hp.last_period_start_date) % COALESCE(hp.cycle_length_days, 28) + 1 <= 16 THEN 'ovulation'
        ELSE 'luteal'
    END as current_phase,
    hp.hormone_goals,
    hp.cycle_sync_workouts,
    hp.cycle_sync_nutrition
FROM hormonal_profiles hp;

COMMENT ON VIEW user_current_cycle_phase IS 'Calculated current cycle day and phase for users with menstrual tracking enabled';

-- View for kegel statistics
CREATE OR REPLACE VIEW user_kegel_stats AS
SELECT
    kp.user_id,
    kp.kegels_enabled,
    kp.target_sessions_per_day,
    COUNT(DISTINCT ks.session_date) as total_days_practiced,
    COUNT(ks.id) as total_sessions,
    COALESCE(SUM(ks.duration_seconds), 0) as total_duration_seconds,
    COALESCE(AVG(ks.duration_seconds), 0)::INTEGER as avg_session_duration,
    COUNT(CASE WHEN ks.session_date = CURRENT_DATE THEN 1 END) as sessions_today,
    COUNT(CASE WHEN ks.session_date >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as sessions_last_7_days,
    (
        SELECT COUNT(DISTINCT d.date)
        FROM generate_series(CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE, '1 day'::interval) d(date)
        WHERE EXISTS (
            SELECT 1 FROM kegel_sessions ks2
            WHERE ks2.user_id = kp.user_id AND ks2.session_date = d.date::DATE
        )
    ) as streak_days_30
FROM kegel_preferences kp
LEFT JOIN kegel_sessions ks ON kp.user_id = ks.user_id
GROUP BY kp.user_id, kp.kegels_enabled, kp.target_sessions_per_day;

COMMENT ON VIEW user_kegel_stats IS 'Aggregated kegel exercise statistics per user';

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to get cycle-appropriate exercises
CREATE OR REPLACE FUNCTION get_cycle_phase_exercise_intensity(p_user_id UUID)
RETURNS TABLE (
    phase TEXT,
    recommended_intensity TEXT,
    avoid_exercises TEXT[],
    recommended_exercises TEXT[]
) AS $$
DECLARE
    v_phase TEXT;
BEGIN
    SELECT current_phase INTO v_phase
    FROM user_current_cycle_phase
    WHERE user_id = p_user_id;

    IF v_phase IS NULL THEN
        RETURN QUERY SELECT
            'not_tracking'::TEXT,
            'normal'::TEXT,
            ARRAY[]::TEXT[],
            ARRAY[]::TEXT[];
        RETURN;
    END IF;

    RETURN QUERY SELECT
        v_phase,
        CASE v_phase
            WHEN 'menstrual' THEN 'light_to_moderate'
            WHEN 'follicular' THEN 'moderate_to_high'
            WHEN 'ovulation' THEN 'high'
            WHEN 'luteal' THEN 'moderate'
            ELSE 'normal'
        END,
        CASE v_phase
            WHEN 'menstrual' THEN ARRAY['high_intensity_interval', 'heavy_lifting', 'inversions']
            WHEN 'luteal' THEN ARRAY['extreme_endurance', 'new_max_attempts']
            ELSE ARRAY[]::TEXT[]
        END,
        CASE v_phase
            WHEN 'menstrual' THEN ARRAY['yoga', 'walking', 'light_stretching', 'swimming']
            WHEN 'follicular' THEN ARRAY['strength_training', 'hiit', 'new_exercises', 'skill_work']
            WHEN 'ovulation' THEN ARRAY['pr_attempts', 'competitions', 'high_intensity', 'group_classes']
            WHEN 'luteal' THEN ARRAY['moderate_cardio', 'pilates', 'strength_maintenance', 'recovery_work']
            ELSE ARRAY[]::TEXT[]
        END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_cycle_phase_exercise_intensity IS 'Returns exercise recommendations based on menstrual cycle phase';

-- Function to check if daily kegel goal is met
CREATE OR REPLACE FUNCTION check_daily_kegel_goal(p_user_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    goal_met BOOLEAN,
    sessions_completed INTEGER,
    target_sessions INTEGER,
    remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(ks.id) >= COALESCE(kp.target_sessions_per_day, 3),
        COUNT(ks.id)::INTEGER,
        COALESCE(kp.target_sessions_per_day, 3),
        GREATEST(0, COALESCE(kp.target_sessions_per_day, 3) - COUNT(ks.id))::INTEGER
    FROM kegel_preferences kp
    LEFT JOIN kegel_sessions ks ON kp.user_id = ks.user_id AND ks.session_date = p_date
    WHERE kp.user_id = p_user_id
    GROUP BY kp.target_sessions_per_day;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_daily_kegel_goal IS 'Check if user has met their daily kegel session goal';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
