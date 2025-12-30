-- Migration: 057_scores_system.sql
-- Description: Add strength scores, readiness scores, and personal records tracking
-- Created: 2024-12-29

-- ============================================================================
-- STRENGTH SCORES TABLE (Per Muscle Group)
-- ============================================================================

CREATE TABLE IF NOT EXISTS strength_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Muscle group identification
  muscle_group TEXT NOT NULL CHECK (muscle_group IN (
    'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
    'quads', 'hamstrings', 'glutes', 'calves', 'core', 'traps'
  )),

  -- Scores
  strength_score INTEGER CHECK (strength_score BETWEEN 0 AND 100),
  strength_level TEXT CHECK (strength_level IN ('beginner', 'novice', 'intermediate', 'advanced', 'elite')),

  -- Supporting data
  best_exercise_name TEXT,
  best_estimated_1rm_kg DECIMAL(6,2),
  bodyweight_ratio DECIMAL(4,2), -- 1rm / user bodyweight

  -- Volume metrics
  weekly_sets INTEGER DEFAULT 0,
  weekly_volume_kg DECIMAL(10,2) DEFAULT 0,

  -- Trend
  previous_score INTEGER,
  score_change INTEGER, -- positive = improvement
  trend TEXT CHECK (trend IN ('improving', 'maintaining', 'declining')),

  -- Timestamps
  calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  period_start DATE,
  period_end DATE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, muscle_group, period_end)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_strength_scores_user ON strength_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_strength_scores_user_muscle ON strength_scores(user_id, muscle_group);
CREATE INDEX IF NOT EXISTS idx_strength_scores_user_date ON strength_scores(user_id, calculated_at DESC);

-- ============================================================================
-- READINESS SCORES TABLE (Daily Check-in)
-- ============================================================================

CREATE TABLE IF NOT EXISTS readiness_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  score_date DATE NOT NULL,

  -- Hooper Index components (1-7 scale, 1=best, 7=worst)
  sleep_quality INTEGER CHECK (sleep_quality BETWEEN 1 AND 7),
  fatigue_level INTEGER CHECK (fatigue_level BETWEEN 1 AND 7),
  stress_level INTEGER CHECK (stress_level BETWEEN 1 AND 7),
  muscle_soreness INTEGER CHECK (muscle_soreness BETWEEN 1 AND 7),

  -- Optional: Mood tracking
  mood INTEGER CHECK (mood BETWEEN 1 AND 7),
  energy_level INTEGER CHECK (energy_level BETWEEN 1 AND 7),

  -- Calculated scores
  hooper_index INTEGER, -- Sum of 4 components (4-28, lower is better)
  readiness_score INTEGER CHECK (readiness_score BETWEEN 0 AND 100), -- Inverted to 0-100
  readiness_level TEXT CHECK (readiness_level IN ('low', 'moderate', 'good', 'optimal')),

  -- AI recommendation
  ai_workout_recommendation TEXT,
  recommended_intensity TEXT CHECK (recommended_intensity IN ('rest', 'light', 'moderate', 'high', 'max')),
  ai_insight TEXT,

  -- Timestamps
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, score_date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_readiness_scores_user ON readiness_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_readiness_scores_user_date ON readiness_scores(user_id, score_date DESC);

-- ============================================================================
-- PERSONAL RECORDS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS personal_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Exercise identification
  exercise_name TEXT NOT NULL,
  exercise_id UUID, -- Optional link to exercises table
  muscle_group TEXT,

  -- Record details
  weight_kg DECIMAL(6,2) NOT NULL,
  reps INTEGER NOT NULL,
  estimated_1rm_kg DECIMAL(6,2) NOT NULL,

  -- Set context
  set_type TEXT DEFAULT 'working', -- 'working', 'amrap', 'failure'
  rpe DECIMAL(3,1), -- Rate of Perceived Exertion

  -- When achieved
  achieved_at TIMESTAMP WITH TIME ZONE NOT NULL,
  workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,

  -- Previous record (for celebration)
  previous_weight_kg DECIMAL(6,2),
  previous_1rm_kg DECIMAL(6,2),
  improvement_kg DECIMAL(6,2),
  improvement_percent DECIMAL(5,2),

  -- Celebration
  is_all_time_pr BOOLEAN DEFAULT FALSE,
  celebration_message TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_personal_records_user ON personal_records(user_id);
CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise ON personal_records(user_id, exercise_name);
CREATE INDEX IF NOT EXISTS idx_personal_records_user_date ON personal_records(user_id, achieved_at DESC);
CREATE INDEX IF NOT EXISTS idx_personal_records_all_time ON personal_records(user_id, exercise_name, is_all_time_pr) WHERE is_all_time_pr = TRUE;

-- ============================================================================
-- NUTRITION SCORES TABLE (Weekly Summary)
-- ============================================================================

CREATE TABLE IF NOT EXISTS nutrition_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Period
  week_start DATE NOT NULL,
  week_end DATE NOT NULL,

  -- Adherence metrics
  days_logged INTEGER DEFAULT 0,
  total_days INTEGER DEFAULT 7,
  adherence_percent DECIMAL(5,2),

  -- Macro adherence (how close to targets)
  calorie_adherence_percent DECIMAL(5,2),
  protein_adherence_percent DECIMAL(5,2),
  carb_adherence_percent DECIMAL(5,2),
  fat_adherence_percent DECIMAL(5,2),

  -- Quality metrics
  avg_health_score DECIMAL(3,1), -- Average of daily health_score from food_logs
  fiber_target_met_days INTEGER DEFAULT 0,

  -- Overall score
  nutrition_score INTEGER CHECK (nutrition_score BETWEEN 0 AND 100),
  nutrition_level TEXT CHECK (nutrition_level IN ('needs_work', 'fair', 'good', 'excellent')),

  -- AI feedback
  ai_weekly_summary TEXT,
  ai_improvement_tips TEXT[],

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, week_start)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_nutrition_scores_user ON nutrition_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_scores_user_week ON nutrition_scores(user_id, week_start DESC);

-- ============================================================================
-- OVERALL FITNESS SCORE TABLE (Combined)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fitness_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Period
  calculated_date DATE NOT NULL,

  -- Component scores
  strength_score INTEGER, -- Average of muscle group scores
  readiness_score INTEGER, -- Today's readiness
  consistency_score INTEGER, -- Workout adherence %
  nutrition_score INTEGER, -- Weekly nutrition score

  -- Overall
  overall_fitness_score INTEGER CHECK (overall_fitness_score BETWEEN 0 AND 100),
  fitness_level TEXT CHECK (fitness_level IN ('beginner', 'developing', 'fit', 'athletic', 'elite')),

  -- Breakdown weights (for transparency)
  strength_weight DECIMAL(3,2) DEFAULT 0.40,
  consistency_weight DECIMAL(3,2) DEFAULT 0.30,
  nutrition_weight DECIMAL(3,2) DEFAULT 0.20,
  readiness_weight DECIMAL(3,2) DEFAULT 0.10,

  -- AI insight
  ai_summary TEXT,
  focus_recommendation TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, calculated_date)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_fitness_scores_user ON fitness_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_fitness_scores_user_date ON fitness_scores(user_id, calculated_date DESC);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE strength_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE readiness_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE fitness_scores ENABLE ROW LEVEL SECURITY;

-- Strength Scores Policies
DROP POLICY IF EXISTS strength_scores_select_policy ON strength_scores;
CREATE POLICY strength_scores_select_policy ON strength_scores
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS strength_scores_insert_policy ON strength_scores;
CREATE POLICY strength_scores_insert_policy ON strength_scores
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS strength_scores_update_policy ON strength_scores;
CREATE POLICY strength_scores_update_policy ON strength_scores
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS strength_scores_service_policy ON strength_scores;
CREATE POLICY strength_scores_service_policy ON strength_scores
  FOR ALL USING (auth.role() = 'service_role');

-- Readiness Scores Policies
DROP POLICY IF EXISTS readiness_scores_select_policy ON readiness_scores;
CREATE POLICY readiness_scores_select_policy ON readiness_scores
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS readiness_scores_insert_policy ON readiness_scores;
CREATE POLICY readiness_scores_insert_policy ON readiness_scores
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS readiness_scores_update_policy ON readiness_scores;
CREATE POLICY readiness_scores_update_policy ON readiness_scores
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS readiness_scores_service_policy ON readiness_scores;
CREATE POLICY readiness_scores_service_policy ON readiness_scores
  FOR ALL USING (auth.role() = 'service_role');

-- Personal Records Policies
DROP POLICY IF EXISTS personal_records_select_policy ON personal_records;
CREATE POLICY personal_records_select_policy ON personal_records
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS personal_records_insert_policy ON personal_records;
CREATE POLICY personal_records_insert_policy ON personal_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS personal_records_service_policy ON personal_records;
CREATE POLICY personal_records_service_policy ON personal_records
  FOR ALL USING (auth.role() = 'service_role');

-- Nutrition Scores Policies
DROP POLICY IF EXISTS nutrition_scores_select_policy ON nutrition_scores;
CREATE POLICY nutrition_scores_select_policy ON nutrition_scores
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_scores_insert_policy ON nutrition_scores;
CREATE POLICY nutrition_scores_insert_policy ON nutrition_scores
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_scores_service_policy ON nutrition_scores;
CREATE POLICY nutrition_scores_service_policy ON nutrition_scores
  FOR ALL USING (auth.role() = 'service_role');

-- Fitness Scores Policies
DROP POLICY IF EXISTS fitness_scores_select_policy ON fitness_scores;
CREATE POLICY fitness_scores_select_policy ON fitness_scores
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fitness_scores_insert_policy ON fitness_scores;
CREATE POLICY fitness_scores_insert_policy ON fitness_scores
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS fitness_scores_service_policy ON fitness_scores;
CREATE POLICY fitness_scores_service_policy ON fitness_scores
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- UPDATED_AT TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_strength_scores_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_strength_scores_updated_at ON strength_scores;
CREATE TRIGGER trigger_update_strength_scores_updated_at
  BEFORE UPDATE ON strength_scores
  FOR EACH ROW EXECUTE FUNCTION update_strength_scores_updated_at();

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- Latest strength scores per muscle group
CREATE OR REPLACE VIEW latest_strength_scores AS
SELECT DISTINCT ON (user_id, muscle_group)
  id,
  user_id,
  muscle_group,
  strength_score,
  strength_level,
  best_exercise_name,
  best_estimated_1rm_kg,
  bodyweight_ratio,
  trend,
  calculated_at
FROM strength_scores
ORDER BY user_id, muscle_group, calculated_at DESC;

-- Today's readiness for all users
CREATE OR REPLACE VIEW today_readiness AS
SELECT *
FROM readiness_scores
WHERE score_date = CURRENT_DATE;

-- All-time PRs per exercise
CREATE OR REPLACE VIEW all_time_prs AS
SELECT DISTINCT ON (user_id, exercise_name)
  id,
  user_id,
  exercise_name,
  muscle_group,
  weight_kg,
  reps,
  estimated_1rm_kg,
  achieved_at
FROM personal_records
WHERE is_all_time_pr = TRUE
ORDER BY user_id, exercise_name, estimated_1rm_kg DESC;

-- Grant permissions on views
GRANT SELECT ON latest_strength_scores TO authenticated;
GRANT SELECT ON today_readiness TO authenticated;
GRANT SELECT ON all_time_prs TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE strength_scores IS 'Per-muscle-group strength scores based on estimated 1RMs';
COMMENT ON TABLE readiness_scores IS 'Daily readiness check-ins using Hooper Index methodology';
COMMENT ON TABLE personal_records IS 'Personal records (PRs) for each exercise';
COMMENT ON TABLE nutrition_scores IS 'Weekly nutrition adherence and quality scores';
COMMENT ON TABLE fitness_scores IS 'Combined overall fitness score from all components';
COMMENT ON VIEW latest_strength_scores IS 'Most recent strength score for each muscle group per user';
COMMENT ON VIEW today_readiness IS 'Today readiness check-ins for all users';
COMMENT ON VIEW all_time_prs IS 'All-time personal records per exercise per user';
