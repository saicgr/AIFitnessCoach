-- Programs Table DDL
-- Stores comprehensive workout programs including celebrity workouts, sport-specific training, and goal-based programs

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing table if it exists (for clean recreation)
DROP TABLE IF EXISTS programs CASCADE;

-- Create programs table
CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Program Identity
    program_name TEXT NOT NULL,                    -- "Brad Pitt Fight Club Workout"
    program_category TEXT NOT NULL,                -- "Celebrity Workout", "Sport Training", "Goal-Based"
    program_subcategory TEXT,                      -- "Actor Transformation", "Cricket", "Fat Loss"

    -- Geographic/Cultural Context
    country TEXT[],                                -- ['India', 'Global'], ['USA']
    celebrity_name TEXT,                           -- "Brad Pitt", "MS Dhoni", "Henry Cavill"

    -- Program Metadata
    difficulty_level TEXT,                         -- "Beginner", "Intermediate", "Advanced", "Elite"
    duration_weeks INT,                            -- Program length (4, 8, 12, 16 weeks)
    sessions_per_week INT,                         -- 3, 4, 5, 6
    session_duration_minutes INT,                  -- Average workout duration

    -- Categorization Tags
    tags TEXT[],                                   -- ['HIIT', 'Strength', 'Muscle Building', 'Celebrity']
    goals TEXT[],                                  -- ['Build Muscle', 'Lose Fat', 'Athletic Performance']

    -- Program Description
    description TEXT,                              -- Full program description
    short_description TEXT,                        -- One-liner summary

    -- Structure (JSONB for flexible workout structure)
    workouts JSONB,                                -- Array of workout objects

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX idx_programs_category ON programs(program_category);
CREATE INDEX idx_programs_country ON programs USING GIN(country);
CREATE INDEX idx_programs_tags ON programs USING GIN(tags);
CREATE INDEX idx_programs_celebrity ON programs(celebrity_name);
CREATE INDEX idx_programs_difficulty ON programs(difficulty_level);
CREATE INDEX idx_programs_goals ON programs USING GIN(goals);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-update updated_at
CREATE TRIGGER update_programs_updated_at BEFORE UPDATE ON programs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE programs IS 'Comprehensive workout programs including celebrity workouts, sport-specific training, and goal-based programs';
COMMENT ON COLUMN programs.program_name IS 'Display name of the program';
COMMENT ON COLUMN programs.program_category IS 'Main category: Celebrity Workout, Sport Training, Goal-Based, etc.';
COMMENT ON COLUMN programs.country IS 'Geographic relevance (India, USA, Global)';
COMMENT ON COLUMN programs.celebrity_name IS 'Associated celebrity name if applicable';
COMMENT ON COLUMN programs.difficulty_level IS 'Beginner, Intermediate, Advanced, or Elite';
COMMENT ON COLUMN programs.duration_weeks IS 'Total program duration in weeks';
COMMENT ON COLUMN programs.sessions_per_week IS 'Number of workout sessions per week';
COMMENT ON COLUMN programs.tags IS 'Searchable tags for program discovery';
COMMENT ON COLUMN programs.goals IS 'Primary fitness goals addressed by the program';
COMMENT ON COLUMN programs.workouts IS 'JSONB array of workout objects with exercises, sets, reps, etc.';

-- Example JSONB structure for workouts column:
-- {
--   "workouts": [
--     {
--       "workout_name": "Upper Body Power",
--       "day": 1,
--       "type": "Strength",
--       "exercises": [
--         {
--           "exercise_name": "Barbell Bench Press",
--           "sets": 4,
--           "reps": "8-10",
--           "rest_seconds": 90,
--           "notes": "Focus on explosive press"
--         }
--       ]
--     }
--   ]
-- }
