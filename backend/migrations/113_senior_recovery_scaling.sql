-- Senior Recovery Scaling Migration
-- Provides age-appropriate workout modifications for older users (60+)
-- Addresses user feedback: "older person. trying to get moving."
--
-- Features:
-- 1. Extended recovery periods between workouts
-- 2. Lower intensity caps for safety
-- 3. Joint-friendly exercise preferences
-- 4. Mandatory extended warmup/cooldown
-- 5. Mobility exercise inclusion

-- Senior-specific recovery settings
CREATE TABLE IF NOT EXISTS senior_recovery_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Recovery multipliers (1.0 = normal, 1.5 = 50% more recovery time)
    recovery_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.5,

    -- Minimum rest days between intense workouts
    min_rest_days_strength INTEGER NOT NULL DEFAULT 2,
    min_rest_days_cardio INTEGER NOT NULL DEFAULT 1,

    -- Max intensity limits (0-100)
    max_intensity_percent INTEGER NOT NULL DEFAULT 75,

    -- Session limits
    max_workout_duration_minutes INTEGER NOT NULL DEFAULT 45,
    max_exercises_per_session INTEGER NOT NULL DEFAULT 6,

    -- Warm-up/cooldown requirements
    extended_warmup_minutes INTEGER NOT NULL DEFAULT 10,
    extended_cooldown_minutes INTEGER NOT NULL DEFAULT 10,

    -- Joint-friendly preferences
    prefer_low_impact BOOLEAN DEFAULT TRUE,
    avoid_high_impact_cardio BOOLEAN DEFAULT TRUE,

    -- Mobility focus
    include_mobility_exercises BOOLEAN DEFAULT TRUE,
    mobility_exercises_per_session INTEGER DEFAULT 2,

    -- Balance focus (important for fall prevention in seniors)
    include_balance_exercises BOOLEAN DEFAULT TRUE,
    balance_exercises_per_session INTEGER DEFAULT 1,

    -- Custom notes for AI prompt context
    custom_notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure one settings record per user
    CONSTRAINT unique_senior_settings_user UNIQUE (user_id)
);

-- Create indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_senior_recovery_settings_user
    ON senior_recovery_settings(user_id);

-- Age-based automatic settings trigger function
CREATE OR REPLACE FUNCTION auto_apply_senior_settings()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_recovery_multiplier DECIMAL(3,2);
    v_max_intensity INTEGER;
    v_min_rest_days INTEGER;
    v_extended_warmup INTEGER;
    v_extended_cooldown INTEGER;
BEGIN
    -- Only apply if user is 60+ and age was updated
    IF NEW.age IS NOT NULL AND NEW.age >= 60 THEN
        -- Calculate age-based settings
        IF NEW.age >= 75 THEN
            v_recovery_multiplier := 2.0;
            v_max_intensity := 65;
            v_min_rest_days := 3;
            v_extended_warmup := 15;
            v_extended_cooldown := 15;
        ELSIF NEW.age >= 70 THEN
            v_recovery_multiplier := 1.75;
            v_max_intensity := 70;
            v_min_rest_days := 2;
            v_extended_warmup := 12;
            v_extended_cooldown := 12;
        ELSIF NEW.age >= 65 THEN
            v_recovery_multiplier := 1.5;
            v_max_intensity := 75;
            v_min_rest_days := 2;
            v_extended_warmup := 10;
            v_extended_cooldown := 10;
        ELSE -- 60-64
            v_recovery_multiplier := 1.25;
            v_max_intensity := 80;
            v_min_rest_days := 1;
            v_extended_warmup := 8;
            v_extended_cooldown := 8;
        END IF;

        -- Insert or update senior settings (don't overwrite if already exists)
        INSERT INTO senior_recovery_settings (
            user_id,
            recovery_multiplier,
            max_intensity_percent,
            min_rest_days_strength,
            min_rest_days_cardio,
            extended_warmup_minutes,
            extended_cooldown_minutes
        )
        VALUES (
            NEW.id,
            v_recovery_multiplier,
            v_max_intensity,
            v_min_rest_days,
            GREATEST(1, v_min_rest_days - 1),
            v_extended_warmup,
            v_extended_cooldown
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_auto_senior_settings ON users;

-- Create trigger for auto-applying senior settings
CREATE TRIGGER trigger_auto_senior_settings
    AFTER INSERT OR UPDATE OF age ON users
    FOR EACH ROW EXECUTE FUNCTION auto_apply_senior_settings();

-- Low-impact exercise alternatives table
CREATE TABLE IF NOT EXISTS low_impact_alternatives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_exercise VARCHAR(200) NOT NULL,
    alternative_exercise VARCHAR(200) NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT unique_low_impact_mapping UNIQUE (original_exercise)
);

-- Insert common low-impact alternatives
INSERT INTO low_impact_alternatives (original_exercise, alternative_exercise, reason) VALUES
    ('Running', 'Walking', 'Lower joint impact while maintaining cardio benefits'),
    ('Jump Squats', 'Bodyweight Squats', 'Eliminates jump impact on knees'),
    ('Burpees', 'Step-Back Burpees', 'Removes explosive movements'),
    ('Box Jumps', 'Step-Ups', 'Controlled movement pattern'),
    ('Jumping Lunges', 'Stationary Lunges', 'Removes ballistic knee stress'),
    ('High Knees', 'Marching in Place', 'Gentler on joints'),
    ('Mountain Climbers', 'Standing Knee Raises', 'Less wrist and shoulder strain'),
    ('Tuck Jumps', 'Chair Squats', 'Eliminates impact'),
    ('Jumping Jacks', 'Step Jacks', 'Lower impact alternative'),
    ('Plyo Push-ups', 'Wall Push-ups', 'Reduced shoulder stress'),
    ('Sprints', 'Brisk Walking', 'Sustained cardio without impact'),
    ('Jump Rope', 'Walking in Place', 'No impact alternative'),
    ('Depth Jumps', 'Box Step Downs', 'Controlled eccentric movement'),
    ('Lunge Jumps', 'Reverse Lunges', 'Stable movement pattern'),
    ('Squat Jumps', 'Chair-Assisted Squats', 'Added stability')
ON CONFLICT (original_exercise) DO NOTHING;

-- Senior mobility exercises table
CREATE TABLE IF NOT EXISTS senior_mobility_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    target_muscles TEXT[], -- e.g., ['hip flexors', 'lower back']
    duration_seconds INTEGER DEFAULT 30,
    sets INTEGER DEFAULT 2,
    reps INTEGER DEFAULT 10,
    difficulty VARCHAR(20) DEFAULT 'easy', -- easy, moderate
    instructions TEXT[],
    video_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT unique_senior_mobility_name UNIQUE (name)
);

-- Insert senior-friendly mobility exercises
INSERT INTO senior_mobility_exercises (name, description, target_muscles, duration_seconds, sets, reps, difficulty, instructions) VALUES
    ('Cat-Cow Stretch', 'Gentle spinal mobility exercise', ARRAY['spine', 'lower back'], 30, 2, 10, 'easy',
     ARRAY['Start on hands and knees', 'Inhale, drop belly and look up (cow)', 'Exhale, round spine and tuck chin (cat)', 'Move slowly and breathe deeply']),
    ('Hip Circles', 'Improves hip joint mobility', ARRAY['hip flexors', 'glutes'], 30, 2, 10, 'easy',
     ARRAY['Stand with feet hip-width apart', 'Place hands on hips', 'Make slow circles with your hips', 'Do both directions']),
    ('Arm Circles', 'Shoulder mobility and warmup', ARRAY['shoulders', 'rotator cuff'], 30, 2, 15, 'easy',
     ARRAY['Stand with arms extended to sides', 'Make small circles forward', 'Gradually increase circle size', 'Reverse direction']),
    ('Ankle Rotations', 'Ankle mobility and stability', ARRAY['ankles', 'calves'], 20, 2, 10, 'easy',
     ARRAY['Sit or stand with support', 'Lift one foot off ground', 'Rotate ankle in circles', 'Do both directions, then switch feet']),
    ('Neck Rolls', 'Cervical spine mobility', ARRAY['neck', 'upper back'], 20, 1, 5, 'easy',
     ARRAY['Sit or stand tall', 'Slowly roll head in half circles (ear to ear)', 'Never roll head backward', 'Keep movements slow and controlled']),
    ('Seated Spinal Twist', 'Thoracic spine rotation', ARRAY['spine', 'obliques'], 30, 2, 5, 'easy',
     ARRAY['Sit in chair with feet flat', 'Place right hand on left knee', 'Gently twist torso left', 'Hold 10-15 seconds, then switch']),
    ('Standing Calf Raises', 'Lower leg strength and mobility', ARRAY['calves', 'ankles'], 30, 2, 10, 'easy',
     ARRAY['Stand near wall for support', 'Rise up on toes slowly', 'Lower heels back down', 'Keep core engaged']),
    ('Shoulder Rolls', 'Shoulder joint lubrication', ARRAY['shoulders', 'upper back'], 20, 2, 10, 'easy',
     ARRAY['Stand or sit tall', 'Roll shoulders forward in circles', 'Then roll shoulders backward', 'Keep neck relaxed']),
    ('Knee Lifts', 'Hip flexor activation', ARRAY['hip flexors', 'core'], 30, 2, 10, 'easy',
     ARRAY['Stand with support nearby', 'Lift one knee to hip height', 'Lower with control', 'Alternate legs']),
    ('Wrist Circles', 'Wrist mobility for weight-bearing exercises', ARRAY['wrists', 'forearms'], 20, 2, 10, 'easy',
     ARRAY['Extend arms in front', 'Make circles with wrists', 'Do both directions', 'Helps prevent wrist strain'])
ON CONFLICT (name) DO NOTHING;

-- Senior workout completion log for recovery tracking
CREATE TABLE IF NOT EXISTS senior_workout_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    workout_type VARCHAR(50) NOT NULL, -- strength, cardio, mixed
    intensity_level INTEGER, -- Actual intensity (0-100)
    duration_minutes INTEGER,
    modifications_applied JSONB, -- List of modifications made
    post_workout_feeling VARCHAR(50), -- great, good, tired, sore, painful
    notes TEXT,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_intensity CHECK (intensity_level BETWEEN 0 AND 100)
);

CREATE INDEX IF NOT EXISTS idx_senior_workout_log_user
    ON senior_workout_log(user_id);
CREATE INDEX IF NOT EXISTS idx_senior_workout_log_completed
    ON senior_workout_log(user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_senior_workout_log_type
    ON senior_workout_log(user_id, workout_type);

-- Function to check recovery status
CREATE OR REPLACE FUNCTION check_senior_recovery_status(
    p_user_id UUID,
    p_workout_type VARCHAR(50)
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_settings RECORD;
    v_last_workout RECORD;
    v_days_since INTEGER;
    v_min_rest INTEGER;
    v_is_ready BOOLEAN;
BEGIN
    -- Get user's senior settings
    SELECT * INTO v_settings
    FROM senior_recovery_settings
    WHERE user_id = p_user_id;

    -- If no settings, user is not a senior - always ready
    IF v_settings IS NULL THEN
        RETURN jsonb_build_object(
            'ready', TRUE,
            'settings_applied', FALSE,
            'message', 'No senior settings found'
        );
    END IF;

    -- Get minimum rest days based on workout type
    IF p_workout_type = 'strength' THEN
        v_min_rest := v_settings.min_rest_days_strength;
    ELSE
        v_min_rest := v_settings.min_rest_days_cardio;
    END IF;

    -- Find last completed workout of this type
    SELECT completed_at INTO v_last_workout
    FROM senior_workout_log
    WHERE user_id = p_user_id
      AND workout_type = p_workout_type
    ORDER BY completed_at DESC
    LIMIT 1;

    -- If no previous workout, ready to go
    IF v_last_workout IS NULL THEN
        RETURN jsonb_build_object(
            'ready', TRUE,
            'days_since_last', NULL,
            'settings_applied', TRUE,
            'message', 'No previous workout found - ready to start!'
        );
    END IF;

    -- Calculate days since last workout
    v_days_since := EXTRACT(DAY FROM NOW() - v_last_workout.completed_at)::INTEGER;
    v_is_ready := v_days_since >= v_min_rest;

    IF v_is_ready THEN
        RETURN jsonb_build_object(
            'ready', TRUE,
            'days_since_last', v_days_since,
            'min_rest_required', v_min_rest,
            'settings_applied', TRUE,
            'recovery_optimal', TRUE,
            'message', 'Well rested and ready for your workout!'
        );
    ELSE
        RETURN jsonb_build_object(
            'ready', FALSE,
            'days_since_last', v_days_since,
            'min_rest_required', v_min_rest,
            'days_until_ready', v_min_rest - v_days_since,
            'settings_applied', TRUE,
            'recommendation', format('Consider resting %s more day(s) for optimal recovery', v_min_rest - v_days_since)
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get senior-adjusted workout parameters
CREATE OR REPLACE FUNCTION get_senior_workout_params(p_user_id UUID)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_settings RECORD;
    v_user_age INTEGER;
BEGIN
    -- Get user age
    SELECT age INTO v_user_age FROM users WHERE id = p_user_id;

    -- Get settings
    SELECT * INTO v_settings
    FROM senior_recovery_settings
    WHERE user_id = p_user_id;

    -- Return null if not a senior or no settings
    IF v_settings IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN jsonb_build_object(
        'user_age', v_user_age,
        'recovery_multiplier', v_settings.recovery_multiplier,
        'max_intensity_percent', v_settings.max_intensity_percent,
        'max_workout_duration_minutes', v_settings.max_workout_duration_minutes,
        'max_exercises_per_session', v_settings.max_exercises_per_session,
        'extended_warmup_minutes', v_settings.extended_warmup_minutes,
        'extended_cooldown_minutes', v_settings.extended_cooldown_minutes,
        'prefer_low_impact', v_settings.prefer_low_impact,
        'avoid_high_impact_cardio', v_settings.avoid_high_impact_cardio,
        'include_mobility_exercises', v_settings.include_mobility_exercises,
        'mobility_exercises_per_session', v_settings.mobility_exercises_per_session,
        'include_balance_exercises', v_settings.include_balance_exercises,
        'balance_exercises_per_session', v_settings.balance_exercises_per_session,
        'min_rest_days_strength', v_settings.min_rest_days_strength,
        'min_rest_days_cardio', v_settings.min_rest_days_cardio,
        'custom_notes', v_settings.custom_notes
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get mobility exercises for senior workouts
CREATE OR REPLACE FUNCTION get_senior_mobility_exercises(p_count INTEGER DEFAULT 2)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN (
        SELECT jsonb_agg(
            jsonb_build_object(
                'name', name,
                'description', description,
                'type', 'mobility',
                'sets', sets,
                'reps', reps,
                'duration_seconds', duration_seconds,
                'instructions', instructions,
                'target_muscles', target_muscles
            )
        )
        FROM (
            SELECT name, description, sets, reps, duration_seconds, instructions, target_muscles
            FROM senior_mobility_exercises
            WHERE is_active = TRUE
            ORDER BY RANDOM()
            LIMIT p_count
        ) sub
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get low-impact alternative for an exercise
CREATE OR REPLACE FUNCTION get_low_impact_alternative(p_exercise_name VARCHAR)
RETURNS VARCHAR
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_alternative VARCHAR;
BEGIN
    SELECT alternative_exercise INTO v_alternative
    FROM low_impact_alternatives
    WHERE LOWER(original_exercise) = LOWER(p_exercise_name);

    RETURN COALESCE(v_alternative, p_exercise_name);
END;
$$ LANGUAGE plpgsql;

-- Enable Row Level Security
ALTER TABLE senior_recovery_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE senior_workout_log ENABLE ROW LEVEL SECURITY;

-- RLS policies for senior_recovery_settings
DROP POLICY IF EXISTS senior_settings_select ON senior_recovery_settings;
CREATE POLICY senior_settings_select ON senior_recovery_settings
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS senior_settings_insert ON senior_recovery_settings;
CREATE POLICY senior_settings_insert ON senior_recovery_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS senior_settings_update ON senior_recovery_settings;
CREATE POLICY senior_settings_update ON senior_recovery_settings
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS senior_settings_delete ON senior_recovery_settings;
CREATE POLICY senior_settings_delete ON senior_recovery_settings
    FOR DELETE USING (auth.uid() = user_id);

-- RLS policies for senior_workout_log
DROP POLICY IF EXISTS senior_log_select ON senior_workout_log;
CREATE POLICY senior_log_select ON senior_workout_log
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS senior_log_insert ON senior_workout_log;
CREATE POLICY senior_log_insert ON senior_workout_log
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS senior_log_update ON senior_workout_log;
CREATE POLICY senior_log_update ON senior_workout_log
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS senior_log_delete ON senior_workout_log;
CREATE POLICY senior_log_delete ON senior_workout_log
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions for service role
GRANT SELECT, INSERT, UPDATE, DELETE ON senior_recovery_settings TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON senior_workout_log TO service_role;
GRANT SELECT ON senior_mobility_exercises TO service_role;
GRANT SELECT ON low_impact_alternatives TO service_role;

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_senior_settings_timestamp()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_senior_settings_updated ON senior_recovery_settings;
CREATE TRIGGER trigger_senior_settings_updated
    BEFORE UPDATE ON senior_recovery_settings
    FOR EACH ROW EXECUTE FUNCTION update_senior_settings_timestamp();

-- Comments for documentation
COMMENT ON TABLE senior_recovery_settings IS 'Age-appropriate recovery settings for senior users (60+)';
COMMENT ON TABLE senior_workout_log IS 'Workout completion tracking for senior recovery monitoring';
COMMENT ON TABLE senior_mobility_exercises IS 'Pre-defined mobility exercises for senior warm-ups';
COMMENT ON TABLE low_impact_alternatives IS 'Mapping of high-impact to low-impact exercise alternatives';
COMMENT ON FUNCTION check_senior_recovery_status IS 'Check if senior user has had adequate recovery time';
COMMENT ON FUNCTION get_senior_workout_params IS 'Get all senior-specific workout parameters for a user';
COMMENT ON FUNCTION auto_apply_senior_settings IS 'Automatically create senior settings when user age is 60+';
