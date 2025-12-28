-- Migration: 047_custom_goals.sql
-- Description: Create custom_goals table for user-defined training objectives
-- Author: Claude AI
-- Date: 2025-12-27

-- =============================================================================
-- CUSTOM GOALS TABLE
-- =============================================================================
-- Stores user's custom fitness goals with AI-generated search keywords.
-- Keywords are generated once by Gemini and cached to avoid API calls during
-- workout generation.
-- =============================================================================

CREATE TABLE IF NOT EXISTS custom_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- User's goal in natural language
    goal_text VARCHAR(500) NOT NULL,

    -- AI-generated data (cached to avoid repeated API calls)
    search_keywords JSONB NOT NULL DEFAULT '[]',  -- Array of keywords for RAG search
    goal_type VARCHAR(50) DEFAULT 'general',      -- 'skill', 'power', 'endurance', 'sport', 'flexibility'
    target_metrics JSONB DEFAULT '{}',            -- e.g., {"box_jump_height_inches": "increase by 4-6"}
    progression_strategy VARCHAR(50) DEFAULT 'linear',  -- 'linear', 'wave', 'periodized', 'skill_based'
    exercise_categories JSONB DEFAULT '[]',       -- Categories like ["plyometrics", "lower body power"]
    muscle_groups JSONB DEFAULT '[]',             -- Primary muscle groups involved
    training_notes TEXT,                          -- AI recommendations for training

    -- Goal management
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 3 CHECK (priority >= 1 AND priority <= 5),  -- 1-5, higher = more focus

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    keywords_updated_at TIMESTAMPTZ DEFAULT NOW()  -- Track when AI keywords were last refreshed
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_custom_goals_user_id ON custom_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_custom_goals_active ON custom_goals(user_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_custom_goals_priority ON custom_goals(user_id, priority DESC) WHERE is_active = TRUE;

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE custom_goals ENABLE ROW LEVEL SECURITY;

-- Users can only see their own goals
CREATE POLICY "Users can view own custom_goals" ON custom_goals
    FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can only insert their own goals
CREATE POLICY "Users can insert own custom_goals" ON custom_goals
    FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can only update their own goals
CREATE POLICY "Users can update own custom_goals" ON custom_goals
    FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Users can only delete their own goals
CREATE POLICY "Users can delete own custom_goals" ON custom_goals
    FOR DELETE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- =============================================================================
-- TRIGGER FOR UPDATED_AT
-- =============================================================================

CREATE OR REPLACE FUNCTION update_custom_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_custom_goals_updated_at
    BEFORE UPDATE ON custom_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_custom_goals_updated_at();

-- =============================================================================
-- ADD COLUMN TO USERS TABLE
-- =============================================================================
-- Quick reference to active custom goal IDs for efficient queries

ALTER TABLE users ADD COLUMN IF NOT EXISTS active_custom_goal_ids JSONB DEFAULT '[]';

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE custom_goals IS 'User-defined custom fitness goals with AI-generated search keywords';
COMMENT ON COLUMN custom_goals.search_keywords IS 'AI-generated keywords for RAG exercise search (cached)';
COMMENT ON COLUMN custom_goals.goal_type IS 'Category: skill, power, endurance, sport, flexibility, mobility, general';
COMMENT ON COLUMN custom_goals.progression_strategy IS 'How to progress: linear, wave, periodized, skill_based';
COMMENT ON COLUMN custom_goals.priority IS 'User priority 1-5, higher means more focus in workout generation';
COMMENT ON COLUMN custom_goals.keywords_updated_at IS 'When AI keywords were last regenerated (refresh periodically)';
