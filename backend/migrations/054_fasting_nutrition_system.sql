-- Migration: 054_fasting_nutrition_system.sql
-- Description: Add comprehensive fasting tracking, nutrition preferences, and unified integration
-- Created: 2024-12-29

-- ============================================================================
-- PART 1: NUTRITION PREFERENCES (For nutrition onboarding)
-- ============================================================================

CREATE TABLE IF NOT EXISTS nutrition_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Goal settings
  nutrition_goal TEXT NOT NULL DEFAULT 'maintain', -- 'lose_fat', 'build_muscle', 'maintain', 'improve_energy', 'eat_healthier', 'recomposition'
  rate_of_change TEXT DEFAULT 'moderate', -- 'slow', 'moderate', 'aggressive'

  -- Calculated targets (BMR/TDEE based)
  calculated_bmr INTEGER,
  calculated_tdee INTEGER,
  target_calories INTEGER,
  target_protein_g INTEGER,
  target_carbs_g INTEGER,
  target_fat_g INTEGER,
  target_fiber_g INTEGER DEFAULT 25,

  -- Diet type
  diet_type TEXT DEFAULT 'balanced', -- 'balanced', 'low_carb', 'keto', 'high_protein', 'vegetarian', 'vegan', 'mediterranean', 'custom'
  custom_carb_percent INTEGER,
  custom_protein_percent INTEGER,
  custom_fat_percent INTEGER,

  -- Restrictions (FDA Big 9 + common)
  allergies TEXT[] DEFAULT '{}', -- Array of allergens
  dietary_restrictions TEXT[] DEFAULT '{}', -- 'vegetarian', 'vegan', 'halal', 'kosher', 'lactose_free', 'gluten_free'
  disliked_foods TEXT[] DEFAULT '{}',

  -- Meal patterns
  meal_pattern TEXT DEFAULT '3_meals', -- '3_meals', '3_meals_snacks', 'if_16_8', 'if_18_6', '5_6_small_meals'

  -- Lifestyle factors
  cooking_skill TEXT DEFAULT 'intermediate', -- 'beginner', 'intermediate', 'advanced'
  cooking_time_minutes INTEGER DEFAULT 30,
  budget_level TEXT DEFAULT 'moderate', -- 'budget', 'moderate', 'no_constraints'

  -- Settings
  show_ai_feedback_after_logging BOOLEAN DEFAULT true,
  calm_mode_enabled BOOLEAN DEFAULT false, -- Hide calorie numbers
  show_weekly_instead_of_daily BOOLEAN DEFAULT false,
  adjust_calories_for_training BOOLEAN DEFAULT true,
  adjust_calories_for_rest BOOLEAN DEFAULT false,

  -- Tracking
  nutrition_onboarding_completed BOOLEAN DEFAULT false,
  onboarding_completed_at TIMESTAMP WITH TIME ZONE,
  last_recalculated_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for nutrition_preferences
ALTER TABLE nutrition_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS nutrition_preferences_select_policy ON nutrition_preferences;
CREATE POLICY nutrition_preferences_select_policy ON nutrition_preferences
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_preferences_insert_policy ON nutrition_preferences;
CREATE POLICY nutrition_preferences_insert_policy ON nutrition_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_preferences_update_policy ON nutrition_preferences;
CREATE POLICY nutrition_preferences_update_policy ON nutrition_preferences
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_preferences_delete_policy ON nutrition_preferences;
CREATE POLICY nutrition_preferences_delete_policy ON nutrition_preferences
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_nutrition_preferences_user ON nutrition_preferences(user_id);

-- ============================================================================
-- PART 2: FASTING RECORDS (Core fasting tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fasting_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,

  -- Timing
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  goal_duration_minutes INTEGER NOT NULL,
  actual_duration_minutes INTEGER,

  -- Protocol
  protocol TEXT NOT NULL DEFAULT '16:8', -- '12:12', '14:10', '16:8', '18:6', '20:4', 'omad', '5:2', 'adf', 'custom'
  protocol_type TEXT NOT NULL DEFAULT 'tre', -- 'tre' (time-restricted), 'modified' (5:2, ADF), 'extended'

  -- Status
  status TEXT DEFAULT 'active', -- 'active', 'completed', 'cancelled'
  completed_goal BOOLEAN DEFAULT false,
  completion_percentage DECIMAL(5,2),

  -- Zones reached (JSON array of zone entries)
  zones_reached JSONB DEFAULT '[]',

  -- User input
  notes TEXT,
  mood_before TEXT, -- 'great', 'good', 'neutral', 'tired', 'hungry'
  mood_after TEXT,
  energy_level_before INTEGER CHECK (energy_level_before >= 1 AND energy_level_before <= 5),
  energy_level_after INTEGER CHECK (energy_level_after >= 1 AND energy_level_after <= 5),

  -- Integration
  ended_by TEXT, -- 'user', 'meal_logged', 'timer'
  breaking_meal_id UUID, -- Reference to food_logs if fast was broken by meal

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for fasting_records
ALTER TABLE fasting_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fasting_records_select_policy ON fasting_records;
CREATE POLICY fasting_records_select_policy ON fasting_records
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_records_insert_policy ON fasting_records;
CREATE POLICY fasting_records_insert_policy ON fasting_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_records_update_policy ON fasting_records;
CREATE POLICY fasting_records_update_policy ON fasting_records
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_records_delete_policy ON fasting_records;
CREATE POLICY fasting_records_delete_policy ON fasting_records
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_fasting_records_user ON fasting_records(user_id);
CREATE INDEX IF NOT EXISTS idx_fasting_records_user_date ON fasting_records(user_id, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_fasting_records_active ON fasting_records(user_id, status) WHERE status = 'active';

-- ============================================================================
-- PART 3: FASTING PREFERENCES
-- ============================================================================

CREATE TABLE IF NOT EXISTS fasting_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Selected protocol
  default_protocol TEXT DEFAULT '16:8',
  custom_fasting_hours INTEGER,
  custom_eating_hours INTEGER,

  -- Schedule
  typical_fast_start_hour INTEGER DEFAULT 20, -- 8pm
  typical_eating_start_hour INTEGER DEFAULT 12, -- 12pm
  fasting_days TEXT[] DEFAULT '{}', -- For 5:2: ['monday', 'thursday']

  -- Notifications
  notifications_enabled BOOLEAN DEFAULT true,
  notify_zone_transitions BOOLEAN DEFAULT true,
  notify_goal_reached BOOLEAN DEFAULT true,
  notify_eating_window_end BOOLEAN DEFAULT true,
  notify_fast_start_reminder BOOLEAN DEFAULT true,

  -- Safety
  safety_screening_completed BOOLEAN DEFAULT false,
  safety_warnings_acknowledged TEXT[] DEFAULT '{}',
  has_medical_conditions BOOLEAN DEFAULT false,

  -- Onboarding
  fasting_onboarding_completed BOOLEAN DEFAULT false,
  onboarding_completed_at TIMESTAMP WITH TIME ZONE,
  experience_level TEXT DEFAULT 'beginner', -- 'beginner', 'intermediate', 'advanced'

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for fasting_preferences
ALTER TABLE fasting_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fasting_preferences_select_policy ON fasting_preferences;
CREATE POLICY fasting_preferences_select_policy ON fasting_preferences
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_preferences_insert_policy ON fasting_preferences;
CREATE POLICY fasting_preferences_insert_policy ON fasting_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_preferences_update_policy ON fasting_preferences;
CREATE POLICY fasting_preferences_update_policy ON fasting_preferences
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_preferences_delete_policy ON fasting_preferences;
CREATE POLICY fasting_preferences_delete_policy ON fasting_preferences
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_fasting_preferences_user ON fasting_preferences(user_id);

-- ============================================================================
-- PART 4: FASTING STREAKS
-- ============================================================================

CREATE TABLE IF NOT EXISTS fasting_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Current streak
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_fasts_completed INTEGER DEFAULT 0,
  total_fasting_minutes INTEGER DEFAULT 0,

  -- Dates
  last_fast_date DATE,
  streak_start_date DATE,

  -- Weekly tracking (for 5:2, ADF)
  fasts_this_week INTEGER DEFAULT 0,
  week_start_date DATE,

  -- Streak freeze system
  freezes_available INTEGER DEFAULT 2,
  freezes_used_this_week INTEGER DEFAULT 0,
  freeze_reset_date DATE,

  -- Weekly goal mode
  weekly_goal_enabled BOOLEAN DEFAULT false,
  weekly_goal_fasts INTEGER DEFAULT 5, -- Complete 5 of 7 days

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for fasting_streaks
ALTER TABLE fasting_streaks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fasting_streaks_select_policy ON fasting_streaks;
CREATE POLICY fasting_streaks_select_policy ON fasting_streaks
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_streaks_insert_policy ON fasting_streaks;
CREATE POLICY fasting_streaks_insert_policy ON fasting_streaks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_streaks_update_policy ON fasting_streaks;
CREATE POLICY fasting_streaks_update_policy ON fasting_streaks
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS fasting_streaks_delete_policy ON fasting_streaks;
CREATE POLICY fasting_streaks_delete_policy ON fasting_streaks
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_fasting_streaks_user ON fasting_streaks(user_id);

-- ============================================================================
-- PART 5: NUTRITION STREAKS (For meal logging consistency)
-- ============================================================================

CREATE TABLE IF NOT EXISTS nutrition_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Current streak
  current_streak_days INTEGER DEFAULT 0,
  streak_start_date DATE,
  last_logged_date DATE,

  -- Streak freezes
  freezes_available INTEGER DEFAULT 2,
  freezes_used_this_week INTEGER DEFAULT 0,
  week_start_date DATE,

  -- Records
  longest_streak_ever INTEGER DEFAULT 0,
  total_days_logged INTEGER DEFAULT 0,

  -- Weekly goal mode
  weekly_goal_enabled BOOLEAN DEFAULT false,
  weekly_goal_days INTEGER DEFAULT 5, -- Log 5 of 7 days
  days_logged_this_week INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for nutrition_streaks
ALTER TABLE nutrition_streaks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS nutrition_streaks_select_policy ON nutrition_streaks;
CREATE POLICY nutrition_streaks_select_policy ON nutrition_streaks
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_streaks_insert_policy ON nutrition_streaks;
CREATE POLICY nutrition_streaks_insert_policy ON nutrition_streaks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_streaks_update_policy ON nutrition_streaks;
CREATE POLICY nutrition_streaks_update_policy ON nutrition_streaks
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS nutrition_streaks_delete_policy ON nutrition_streaks;
CREATE POLICY nutrition_streaks_delete_policy ON nutrition_streaks
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_nutrition_streaks_user ON nutrition_streaks(user_id);

-- ============================================================================
-- PART 6: DAILY UNIFIED STATE (For integration tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS daily_unified_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,

  -- Fasting
  fasting_protocol TEXT,
  is_fasting_day BOOLEAN DEFAULT false, -- For 5:2, ADF
  fasted_hours INTEGER DEFAULT 0,
  fasting_record_id UUID REFERENCES fasting_records(id),

  -- Workout
  workout_completed BOOLEAN DEFAULT false,
  workout_type TEXT, -- 'strength', 'cardio', 'hiit', 'flexibility'
  workout_intensity TEXT, -- 'low', 'moderate', 'high'
  trained_fasted BOOLEAN DEFAULT false,
  workout_id UUID,

  -- Nutrition
  calorie_target INTEGER,
  calorie_actual INTEGER DEFAULT 0,
  protein_target_g INTEGER,
  protein_actual_g INTEGER DEFAULT 0,
  meals_logged INTEGER DEFAULT 0,
  post_workout_meal_logged BOOLEAN DEFAULT false,

  -- Computed adjustments
  target_adjustment_reason TEXT, -- 'training_day', 'rest_day', 'fasting_day', null

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  UNIQUE(user_id, date)
);

-- RLS for daily_unified_state
ALTER TABLE daily_unified_state ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS daily_unified_state_select_policy ON daily_unified_state;
CREATE POLICY daily_unified_state_select_policy ON daily_unified_state
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS daily_unified_state_insert_policy ON daily_unified_state;
CREATE POLICY daily_unified_state_insert_policy ON daily_unified_state
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS daily_unified_state_update_policy ON daily_unified_state;
CREATE POLICY daily_unified_state_update_policy ON daily_unified_state
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS daily_unified_state_delete_policy ON daily_unified_state;
CREATE POLICY daily_unified_state_delete_policy ON daily_unified_state
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_daily_unified_state_user_date ON daily_unified_state(user_id, date DESC);

-- ============================================================================
-- PART 7: WEIGHT LOGS (For adaptive TDEE)
-- ============================================================================

CREATE TABLE IF NOT EXISTS weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  weight_kg DECIMAL(5,2) NOT NULL,
  logged_at TIMESTAMP WITH TIME ZONE NOT NULL,
  source TEXT DEFAULT 'manual', -- 'manual', 'apple_health', 'google_fit', 'withings'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for weight_logs
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS weight_logs_select_policy ON weight_logs;
CREATE POLICY weight_logs_select_policy ON weight_logs
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS weight_logs_insert_policy ON weight_logs;
CREATE POLICY weight_logs_insert_policy ON weight_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS weight_logs_update_policy ON weight_logs;
CREATE POLICY weight_logs_update_policy ON weight_logs
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS weight_logs_delete_policy ON weight_logs;
CREATE POLICY weight_logs_delete_policy ON weight_logs
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_weight_logs_user ON weight_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date ON weight_logs(user_id, logged_at DESC);

-- ============================================================================
-- PART 8: ADAPTIVE NUTRITION CALCULATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS adaptive_nutrition_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  calculated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,

  -- Input data
  avg_daily_intake INTEGER,
  start_trend_weight_kg DECIMAL(5,2),
  end_trend_weight_kg DECIMAL(5,2),
  days_logged INTEGER,
  weight_entries INTEGER,

  -- Calculated values
  calculated_tdee INTEGER,
  weight_change_kg DECIMAL(5,2),
  weekly_rate_kg DECIMAL(4,2),

  -- Quality metrics
  data_quality_score DECIMAL(3,2), -- 0-1
  confidence_level TEXT, -- 'low', 'medium', 'high'

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for adaptive_nutrition_calculations
ALTER TABLE adaptive_nutrition_calculations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS adaptive_nutrition_calculations_select_policy ON adaptive_nutrition_calculations;
CREATE POLICY adaptive_nutrition_calculations_select_policy ON adaptive_nutrition_calculations
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS adaptive_nutrition_calculations_insert_policy ON adaptive_nutrition_calculations;
CREATE POLICY adaptive_nutrition_calculations_insert_policy ON adaptive_nutrition_calculations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_adaptive_calculations_user ON adaptive_nutrition_calculations(user_id, calculated_at DESC);

-- ============================================================================
-- PART 9: WEEKLY NUTRITION RECOMMENDATIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS weekly_nutrition_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,

  -- Current state
  current_goal TEXT, -- 'lose', 'maintain', 'gain'
  target_rate_per_week DECIMAL(4,2), -- kg per week

  -- Calculated recommendations
  calculated_tdee INTEGER,
  recommended_calories INTEGER,
  recommended_protein_g INTEGER,
  recommended_carbs_g INTEGER,
  recommended_fat_g INTEGER,

  -- Explanation
  adjustment_reason TEXT,
  adjustment_amount INTEGER, -- Difference from previous week

  -- User response
  user_accepted BOOLEAN DEFAULT false,
  user_modified BOOLEAN DEFAULT false,
  modified_calories INTEGER,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS for weekly_nutrition_recommendations
ALTER TABLE weekly_nutrition_recommendations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS weekly_nutrition_recommendations_select_policy ON weekly_nutrition_recommendations;
CREATE POLICY weekly_nutrition_recommendations_select_policy ON weekly_nutrition_recommendations
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS weekly_nutrition_recommendations_insert_policy ON weekly_nutrition_recommendations;
CREATE POLICY weekly_nutrition_recommendations_insert_policy ON weekly_nutrition_recommendations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS weekly_nutrition_recommendations_update_policy ON weekly_nutrition_recommendations;
CREATE POLICY weekly_nutrition_recommendations_update_policy ON weekly_nutrition_recommendations
  FOR UPDATE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_weekly_recommendations_user ON weekly_nutrition_recommendations(user_id, week_start DESC);

-- ============================================================================
-- PART 10: UPDATE TRIGGERS
-- ============================================================================

-- Trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to new tables
DROP TRIGGER IF EXISTS update_nutrition_preferences_updated_at ON nutrition_preferences;
CREATE TRIGGER update_nutrition_preferences_updated_at
  BEFORE UPDATE ON nutrition_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_fasting_records_updated_at ON fasting_records;
CREATE TRIGGER update_fasting_records_updated_at
  BEFORE UPDATE ON fasting_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_fasting_preferences_updated_at ON fasting_preferences;
CREATE TRIGGER update_fasting_preferences_updated_at
  BEFORE UPDATE ON fasting_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_fasting_streaks_updated_at ON fasting_streaks;
CREATE TRIGGER update_fasting_streaks_updated_at
  BEFORE UPDATE ON fasting_streaks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_nutrition_streaks_updated_at ON nutrition_streaks;
CREATE TRIGGER update_nutrition_streaks_updated_at
  BEFORE UPDATE ON nutrition_streaks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_unified_state_updated_at ON daily_unified_state;
CREATE TRIGGER update_daily_unified_state_updated_at
  BEFORE UPDATE ON daily_unified_state
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PART 11: ADD COLUMNS TO USERS TABLE FOR INTEGRATION FLAGS
-- ============================================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS show_fasting_workout_warnings BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fasting_enabled BOOLEAN DEFAULT false;

-- ============================================================================
-- PART 12: HELPFUL VIEWS
-- ============================================================================

-- View for active fasts (currently in progress)
CREATE OR REPLACE VIEW active_fasts AS
SELECT
  fr.*,
  fp.default_protocol,
  fp.typical_fast_start_hour,
  fp.typical_eating_start_hour,
  EXTRACT(EPOCH FROM (now() - fr.start_time)) / 60 AS elapsed_minutes,
  CASE
    WHEN EXTRACT(EPOCH FROM (now() - fr.start_time)) / 3600 < 4 THEN 'fed'
    WHEN EXTRACT(EPOCH FROM (now() - fr.start_time)) / 3600 < 8 THEN 'post_absorptive'
    WHEN EXTRACT(EPOCH FROM (now() - fr.start_time)) / 3600 < 12 THEN 'early_fasting'
    WHEN EXTRACT(EPOCH FROM (now() - fr.start_time)) / 3600 < 16 THEN 'fat_burning'
    WHEN EXTRACT(EPOCH FROM (now() - fr.start_time)) / 3600 < 24 THEN 'ketosis'
    WHEN EXTRACT(EPOCH FROM (now() - fr.start_time)) / 3600 < 48 THEN 'deep_ketosis'
    ELSE 'extended'
  END AS current_zone
FROM fasting_records fr
LEFT JOIN fasting_preferences fp ON fr.user_id = fp.user_id
WHERE fr.status = 'active';

-- View for fasting statistics
CREATE OR REPLACE VIEW fasting_stats AS
SELECT
  user_id,
  COUNT(*) FILTER (WHERE completed_goal = true) AS completed_fasts,
  COUNT(*) AS total_fasts,
  COALESCE(AVG(actual_duration_minutes) FILTER (WHERE status = 'completed'), 0) AS avg_duration_minutes,
  COALESCE(MAX(actual_duration_minutes), 0) AS longest_fast_minutes,
  COALESCE(SUM(actual_duration_minutes) FILTER (WHERE status = 'completed'), 0) AS total_fasting_minutes
FROM fasting_records
GROUP BY user_id;

-- Grant access to views
GRANT SELECT ON active_fasts TO authenticated;
GRANT SELECT ON fasting_stats TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
