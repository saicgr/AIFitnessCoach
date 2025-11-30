-- Migration: Add program_variants table for intensity and duration variations
-- This table will store all 4,554 pre-generated program variants
-- (253 base programs × 3 intensities × 6 durations = 4,554 total)

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create program_variants table
CREATE TABLE IF NOT EXISTS program_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Link to base program
    base_program_id UUID NOT NULL REFERENCES programs(id) ON DELETE CASCADE,

    -- Variant parameters
    intensity_level TEXT NOT NULL CHECK (intensity_level IN ('Easy', 'Medium', 'Hard')),
    duration_weeks INT NOT NULL CHECK (duration_weeks IN (2, 3, 4, 6, 8, 12)),

    -- Variant metadata (inherited from base program)
    variant_name TEXT NOT NULL,
    program_category TEXT NOT NULL,
    program_subcategory TEXT,
    sessions_per_week INT NOT NULL,
    session_duration_minutes INT NOT NULL,

    -- Tags and goals (copied from base for easier filtering)
    tags TEXT[],
    goals TEXT[],

    -- Generated workout structure (JSONB format matching programs.workouts)
    workouts JSONB NOT NULL,

    -- Generation metadata for analytics
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    generation_cost_usd DECIMAL(10, 4) DEFAULT 0.20,
    generation_model TEXT DEFAULT 'gpt-4',
    generation_tokens INT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure uniqueness: one variant per (program, intensity, duration)
    UNIQUE (base_program_id, intensity_level, duration_weeks)
);

-- Indexes for efficient querying
CREATE INDEX idx_program_variants_base_program ON program_variants(base_program_id);
CREATE INDEX idx_program_variants_intensity ON program_variants(intensity_level);
CREATE INDEX idx_program_variants_duration ON program_variants(duration_weeks);
CREATE INDEX idx_program_variants_lookup ON program_variants(base_program_id, intensity_level, duration_weeks);
CREATE INDEX idx_program_variants_category ON program_variants(program_category);
CREATE INDEX idx_program_variants_tags ON program_variants USING GIN(tags);
CREATE INDEX idx_program_variants_goals ON program_variants USING GIN(goals);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_program_variants_updated_at
BEFORE UPDATE ON program_variants
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE program_variants IS 'Pre-generated program variations with different intensity levels and durations. Total expected: 4,554 variants (253 programs × 3 intensities × 6 durations)';
COMMENT ON COLUMN program_variants.intensity_level IS 'Easy, Medium, or Hard - affects sets, reps, rest periods, and exercise selection';
COMMENT ON COLUMN program_variants.duration_weeks IS 'Program length: 2, 3, 4, 6, 8, or 12 weeks - affects overall program structure';
COMMENT ON COLUMN program_variants.variant_name IS 'Human-readable name like "Brad Pitt Fight Club Workout (Hard, 12 weeks)"';
COMMENT ON COLUMN program_variants.workouts IS 'Generated workout plan in JSONB format with exercises, sets, reps, rest periods';
