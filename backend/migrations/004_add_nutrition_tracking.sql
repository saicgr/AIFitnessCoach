-- FitWiz - Nutrition Tracking Schema
-- Adds food logs table and nutrition targets to users

-- Add nutrition target columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_calorie_target INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_protein_target_g DECIMAL(6,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_carbs_target_g DECIMAL(6,2);
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_fat_target_g DECIMAL(6,2);

-- Food logs table for tracking meals via image analysis
CREATE TABLE IF NOT EXISTS food_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Meal metadata
    meal_type VARCHAR(20),             -- breakfast, lunch, dinner, snack
    logged_at TIMESTAMPTZ DEFAULT NOW(),

    -- Nutrition data (from AI analysis)
    food_items JSONB DEFAULT '[]',     -- [{name: "chicken", amount: "150g", calories: 250, protein_g: 30, carbs_g: 0, fat_g: 5}, ...]
    total_calories INTEGER,
    protein_g DECIMAL(6,2),
    carbs_g DECIMAL(6,2),
    fat_g DECIMAL(6,2),
    fiber_g DECIMAL(6,2),

    -- AI feedback
    ai_feedback TEXT,                  -- Coaching commentary
    health_score INTEGER,              -- 1-10 rating

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_food_logs_user_id ON food_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_food_logs_logged_at ON food_logs(logged_at);
CREATE INDEX IF NOT EXISTS idx_food_logs_user_date ON food_logs(user_id, logged_at);
