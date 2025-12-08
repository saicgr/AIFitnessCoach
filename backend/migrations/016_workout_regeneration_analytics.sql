-- Migration 016: Workout Regeneration Analytics
-- Tracks user customization choices when regenerating workouts for analysis

-- Add equipment column to workouts table if not exists
-- This stores the user-selected equipment for the workout
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'workouts' AND column_name = 'equipment') THEN
        ALTER TABLE workouts ADD COLUMN equipment JSONB DEFAULT '[]';
    END IF;
END $$;

-- Add workout_type_override column to track when user explicitly chooses a workout type
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'workouts' AND column_name = 'workout_type_override') THEN
        ALTER TABLE workouts ADD COLUMN workout_type_override VARCHAR;
    END IF;
END $$;

-- Create workout_regenerations table to track all regeneration events
CREATE TABLE IF NOT EXISTS workout_regenerations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    original_workout_id UUID NOT NULL,
    new_workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,

    -- User selections
    selected_difficulty VARCHAR,
    selected_duration_minutes INTEGER,
    selected_workout_type VARCHAR,
    selected_equipment JSONB DEFAULT '[]',
    selected_focus_areas JSONB DEFAULT '[]',
    selected_injuries JSONB DEFAULT '[]',

    -- Custom "Other" inputs (for AI learning)
    custom_focus_area VARCHAR,
    custom_injury VARCHAR,

    -- Generation metadata
    generation_method VARCHAR DEFAULT 'ai',  -- 'ai', 'rag', 'rag_regenerate'
    used_rag BOOLEAN DEFAULT FALSE,
    generation_time_ms INTEGER,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_regenerations_user_id ON workout_regenerations(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_regenerations_created_at ON workout_regenerations(created_at);
CREATE INDEX IF NOT EXISTS idx_workout_regenerations_workout_type ON workout_regenerations(selected_workout_type);

-- Create custom_inputs table to aggregate user-provided custom focus areas and injuries
-- This helps build a database of common custom inputs for future suggestions
CREATE TABLE IF NOT EXISTS custom_workout_inputs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    input_type VARCHAR NOT NULL,  -- 'focus_area' or 'injury'
    input_value VARCHAR NOT NULL,
    normalized_value VARCHAR,  -- AI-normalized version for grouping
    usage_count INTEGER DEFAULT 1,
    first_used_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_custom_inputs_type ON custom_workout_inputs(input_type);
CREATE INDEX IF NOT EXISTS idx_custom_inputs_value ON custom_workout_inputs(input_value);
CREATE UNIQUE INDEX IF NOT EXISTS idx_custom_inputs_unique ON custom_workout_inputs(user_id, input_type, input_value);

-- Create equipment_preferences table for tracking popular equipment combinations
CREATE TABLE IF NOT EXISTS equipment_usage_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_combination JSONB NOT NULL,  -- Array of equipment names
    combination_hash VARCHAR NOT NULL,  -- Hash for quick lookup
    usage_count INTEGER DEFAULT 1,
    first_used_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    avg_workout_rating DOUBLE PRECISION,  -- If user rates workouts
    UNIQUE(user_id, combination_hash)
);

CREATE INDEX IF NOT EXISTS idx_equipment_usage_user_id ON equipment_usage_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_equipment_usage_hash ON equipment_usage_analytics(combination_hash);

-- Create analytics view for regeneration patterns
CREATE OR REPLACE VIEW regeneration_analytics AS
SELECT
    wr.user_id,
    u.fitness_level,
    DATE_TRUNC('week', wr.created_at) as week,
    COUNT(*) as regeneration_count,

    -- Most popular workout types
    MODE() WITHIN GROUP (ORDER BY wr.selected_workout_type) as most_common_workout_type,

    -- Most popular difficulty
    MODE() WITHIN GROUP (ORDER BY wr.selected_difficulty) as most_common_difficulty,

    -- Average duration preference
    AVG(wr.selected_duration_minutes) as avg_duration_minutes,

    -- Custom input usage
    COUNT(wr.custom_focus_area) FILTER (WHERE wr.custom_focus_area IS NOT NULL) as custom_focus_area_count,
    COUNT(wr.custom_injury) FILTER (WHERE wr.custom_injury IS NOT NULL) as custom_injury_count,

    -- RAG usage
    SUM(CASE WHEN wr.used_rag THEN 1 ELSE 0 END) as rag_regenerations,

    -- Average generation time
    AVG(wr.generation_time_ms) as avg_generation_time_ms
FROM workout_regenerations wr
JOIN users u ON wr.user_id = u.id
GROUP BY wr.user_id, u.fitness_level, DATE_TRUNC('week', wr.created_at);

-- Create view for popular equipment combinations across all users
CREATE OR REPLACE VIEW popular_equipment_combinations AS
SELECT
    equipment_combination,
    SUM(usage_count) as total_uses,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(avg_workout_rating) as avg_rating
FROM equipment_usage_analytics
GROUP BY equipment_combination
ORDER BY total_uses DESC;

-- Create view for custom inputs aggregation (for adding to suggestion lists)
CREATE OR REPLACE VIEW popular_custom_inputs AS
SELECT
    input_type,
    input_value,
    normalized_value,
    COUNT(DISTINCT user_id) as unique_users,
    SUM(usage_count) as total_uses,
    MIN(first_used_at) as first_seen,
    MAX(last_used_at) as last_seen
FROM custom_workout_inputs
GROUP BY input_type, input_value, normalized_value
HAVING COUNT(DISTINCT user_id) >= 2  -- Only show inputs used by 2+ users
ORDER BY total_uses DESC;

-- Enable RLS on new tables
ALTER TABLE workout_regenerations ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_workout_inputs ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_usage_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can manage own workout_regenerations" ON workout_regenerations
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own custom_workout_inputs" ON custom_workout_inputs
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

CREATE POLICY "Users can manage own equipment_usage_analytics" ON equipment_usage_analytics
    FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Function to record a regeneration event
CREATE OR REPLACE FUNCTION record_workout_regeneration(
    p_user_id UUID,
    p_original_workout_id UUID,
    p_new_workout_id UUID,
    p_difficulty VARCHAR DEFAULT NULL,
    p_duration_minutes INTEGER DEFAULT NULL,
    p_workout_type VARCHAR DEFAULT NULL,
    p_equipment JSONB DEFAULT '[]',
    p_focus_areas JSONB DEFAULT '[]',
    p_injuries JSONB DEFAULT '[]',
    p_custom_focus_area VARCHAR DEFAULT NULL,
    p_custom_injury VARCHAR DEFAULT NULL,
    p_generation_method VARCHAR DEFAULT 'ai',
    p_used_rag BOOLEAN DEFAULT FALSE,
    p_generation_time_ms INTEGER DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_regeneration_id UUID;
BEGIN
    -- Insert regeneration record
    INSERT INTO workout_regenerations (
        user_id, original_workout_id, new_workout_id,
        selected_difficulty, selected_duration_minutes, selected_workout_type,
        selected_equipment, selected_focus_areas, selected_injuries,
        custom_focus_area, custom_injury,
        generation_method, used_rag, generation_time_ms
    ) VALUES (
        p_user_id, p_original_workout_id, p_new_workout_id,
        p_difficulty, p_duration_minutes, p_workout_type,
        p_equipment, p_focus_areas, p_injuries,
        p_custom_focus_area, p_custom_injury,
        p_generation_method, p_used_rag, p_generation_time_ms
    ) RETURNING id INTO v_regeneration_id;

    -- Record custom focus area if provided
    IF p_custom_focus_area IS NOT NULL AND p_custom_focus_area != '' THEN
        INSERT INTO custom_workout_inputs (user_id, input_type, input_value, last_used_at)
        VALUES (p_user_id, 'focus_area', p_custom_focus_area, NOW())
        ON CONFLICT (user_id, input_type, input_value)
        DO UPDATE SET
            usage_count = custom_workout_inputs.usage_count + 1,
            last_used_at = NOW();
    END IF;

    -- Record custom injury if provided
    IF p_custom_injury IS NOT NULL AND p_custom_injury != '' THEN
        INSERT INTO custom_workout_inputs (user_id, input_type, input_value, last_used_at)
        VALUES (p_user_id, 'injury', p_custom_injury, NOW())
        ON CONFLICT (user_id, input_type, input_value)
        DO UPDATE SET
            usage_count = custom_workout_inputs.usage_count + 1,
            last_used_at = NOW();
    END IF;

    -- Record equipment combination if provided
    IF jsonb_array_length(p_equipment) > 0 THEN
        INSERT INTO equipment_usage_analytics (
            user_id, equipment_combination, combination_hash, last_used_at
        ) VALUES (
            p_user_id,
            p_equipment,
            md5(p_equipment::text),
            NOW()
        )
        ON CONFLICT (user_id, combination_hash)
        DO UPDATE SET
            usage_count = equipment_usage_analytics.usage_count + 1,
            last_used_at = NOW();
    END IF;

    RETURN v_regeneration_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION record_workout_regeneration TO authenticated;

COMMENT ON TABLE workout_regenerations IS 'Tracks all workout regeneration events for analytics';
COMMENT ON TABLE custom_workout_inputs IS 'Aggregates custom focus areas and injuries for future suggestions';
COMMENT ON TABLE equipment_usage_analytics IS 'Tracks popular equipment combinations per user';
COMMENT ON VIEW regeneration_analytics IS 'Weekly aggregated regeneration patterns per user';
COMMENT ON VIEW popular_equipment_combinations IS 'Most popular equipment combinations across all users';
COMMENT ON VIEW popular_custom_inputs IS 'Custom inputs used by multiple users for potential addition to default lists';
