-- Migration: User Insights and Weekly Progress
-- Created: 2025-12-04
-- Purpose: Store AI-generated micro-insights and weekly program progress

-- ============================================
-- user_insights - AI-generated personalized micro-insights
-- ============================================
CREATE TABLE IF NOT EXISTS user_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Insight content
    insight_type VARCHAR(50) NOT NULL,  -- 'performance', 'consistency', 'motivation', 'tip', 'milestone'
    message TEXT NOT NULL,
    emoji VARCHAR(10),  -- Optional emoji for display

    -- Context that generated this insight
    context_data JSONB,  -- e.g., {"streak": 5, "improvement_pct": 15}

    -- Display settings
    priority INTEGER DEFAULT 1,  -- Higher = more important
    is_active BOOLEAN DEFAULT true,  -- Can be dismissed
    expires_at TIMESTAMP WITH TIME ZONE,  -- Optional expiration

    -- Timestamps
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE user_insights IS 'AI-generated personalized micro-insights for users';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_insights_user_id ON user_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_user_insights_type ON user_insights(insight_type);
CREATE INDEX IF NOT EXISTS idx_user_insights_active ON user_insights(is_active, expires_at);

-- ============================================
-- weekly_program_progress - Track user's weekly program completion
-- ============================================
CREATE TABLE IF NOT EXISTS weekly_program_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Week identification
    week_start_date DATE NOT NULL,  -- Monday of the week
    year INTEGER NOT NULL,
    week_number INTEGER NOT NULL,  -- ISO week number

    -- Progress tracking
    planned_workouts INTEGER DEFAULT 0,
    completed_workouts INTEGER DEFAULT 0,
    total_duration_minutes INTEGER DEFAULT 0,
    total_calories_burned INTEGER DEFAULT 0,

    -- Workout types breakdown
    workout_types_completed JSONB DEFAULT '{}',  -- {"strength": 2, "cardio": 1}

    -- Goals for the week
    target_workouts INTEGER,  -- From user preferences
    target_duration_minutes INTEGER,

    -- Achievements
    goals_met BOOLEAN DEFAULT false,
    streak_continued BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, week_start_date)
);

COMMENT ON TABLE weekly_program_progress IS 'Tracks weekly workout program progress per user';

-- Indexes
CREATE INDEX IF NOT EXISTS idx_weekly_progress_user ON weekly_program_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_progress_week ON weekly_program_progress(week_start_date DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_progress_year_week ON weekly_program_progress(year, week_number);

-- Enable Row Level Security
ALTER TABLE user_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_program_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS user_insights_select_policy ON user_insights;
CREATE POLICY user_insights_select_policy ON user_insights
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_insights_service_policy ON user_insights;
CREATE POLICY user_insights_service_policy ON user_insights
    FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS weekly_progress_select_policy ON weekly_program_progress;
CREATE POLICY weekly_progress_select_policy ON weekly_program_progress
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS weekly_progress_service_policy ON weekly_program_progress;
CREATE POLICY weekly_progress_service_policy ON weekly_program_progress
    FOR ALL USING (auth.role() = 'service_role');
