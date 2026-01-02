-- Migration: 121_holistic_weekly_plans.sql
-- Description: Create tables for holistic weekly plans integrating workouts, nutrition, and fasting
-- Date: 2026-01-01

-- ============================================================================
-- WEEKLY PLANS TABLE
-- ============================================================================
-- Stores the weekly holistic plan that coordinates workouts, nutrition, and fasting

CREATE TABLE IF NOT EXISTS weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),

  -- Plan settings
  workout_days JSONB DEFAULT '[]'::JSONB, -- Array of day indices [0,1,3,4] (Mon=0, Sun=6)
  fasting_protocol TEXT, -- '16:8', '18:6', 'OMAD', etc.
  nutrition_strategy TEXT DEFAULT 'workout_aware' CHECK (nutrition_strategy IN ('workout_aware', 'static', 'cutting', 'bulking', 'maintenance')),

  -- Base nutrition targets (adjusted per day based on strategy)
  base_calorie_target INT,
  base_protein_target_g DECIMAL,
  base_carbs_target_g DECIMAL,
  base_fat_target_g DECIMAL,

  -- AI generation metadata
  generated_at TIMESTAMPTZ,
  generation_prompt TEXT,
  ai_model_used TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Constraints
  UNIQUE(user_id, week_start_date)
);

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_weekly_plans_user_date ON weekly_plans(user_id, week_start_date DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_status ON weekly_plans(user_id, status);

COMMENT ON TABLE weekly_plans IS 'Weekly holistic plans coordinating workouts, nutrition, and fasting';
COMMENT ON COLUMN weekly_plans.workout_days IS 'Array of day indices (0=Monday, 6=Sunday) when workouts are scheduled';
COMMENT ON COLUMN weekly_plans.nutrition_strategy IS 'How nutrition targets adjust: workout_aware increases on training days';

-- ============================================================================
-- DAILY PLAN ENTRIES TABLE
-- ============================================================================
-- Stores daily details including nutrition targets, fasting windows, and meal suggestions

CREATE TABLE IF NOT EXISTS daily_plan_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  weekly_plan_id UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
  plan_date DATE NOT NULL,
  day_type TEXT NOT NULL CHECK (day_type IN ('training', 'rest', 'active_recovery')),

  -- Workout reference (null for rest days)
  workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
  workout_time TIME, -- Scheduled workout time
  workout_duration_minutes INT,

  -- Nutrition targets for this specific day (adjusted from base)
  calorie_target INT NOT NULL,
  protein_target_g DECIMAL NOT NULL,
  carbs_target_g DECIMAL NOT NULL,
  fat_target_g DECIMAL NOT NULL,
  fiber_target_g DECIMAL,

  -- Fasting window for this day
  fasting_start_time TIME,
  eating_window_start TIME,
  eating_window_end TIME,
  fasting_protocol TEXT,
  fasting_duration_hours INT,

  -- AI-generated meal suggestions (JSONB array)
  -- Format: [{meal_type, suggested_time, foods: [{name, amount, calories, protein_g, carbs_g, fat_g}], macros, notes}]
  meal_suggestions JSONB DEFAULT '[]'::JSONB,

  -- Coordination warnings/notes
  -- Format: [{type, message, severity, suggestion}]
  coordination_notes JSONB DEFAULT '[]'::JSONB,

  -- Tracking
  nutrition_logged BOOLEAN DEFAULT false,
  workout_completed BOOLEAN DEFAULT false,
  fasting_completed BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  -- Constraints
  UNIQUE(weekly_plan_id, plan_date)
);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_daily_plan_entries_plan ON daily_plan_entries(weekly_plan_id);
CREATE INDEX IF NOT EXISTS idx_daily_plan_entries_date ON daily_plan_entries(plan_date);
CREATE INDEX IF NOT EXISTS idx_daily_plan_entries_workout ON daily_plan_entries(workout_id) WHERE workout_id IS NOT NULL;

COMMENT ON TABLE daily_plan_entries IS 'Daily plan details with workout-aware nutrition and coordinated fasting';
COMMENT ON COLUMN daily_plan_entries.meal_suggestions IS 'AI-generated meal suggestions with timing and macros';
COMMENT ON COLUMN daily_plan_entries.coordination_notes IS 'Warnings about fasting-workout conflicts, etc.';

-- ============================================================================
-- MEAL PLAN TEMPLATES TABLE
-- ============================================================================
-- Stores reusable meal templates for quick meal planning

CREATE TABLE IF NOT EXISTS meal_plan_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  day_type TEXT CHECK (day_type IN ('training', 'rest', 'any')),

  -- Meal structure
  -- Format: [{meal_type, suggested_time, foods: [{name, amount, calories, protein_g, carbs_g, fat_g}], macros, notes}]
  meals JSONB NOT NULL DEFAULT '[]'::JSONB,

  -- Total macros for all meals combined
  total_calories INT,
  total_protein_g DECIMAL,
  total_carbs_g DECIMAL,
  total_fat_g DECIMAL,

  -- Metadata
  tags TEXT[] DEFAULT '{}', -- ['high_protein', 'pre_workout', 'post_workout', 'low_carb']
  is_favorite BOOLEAN DEFAULT false,
  is_ai_generated BOOLEAN DEFAULT false,
  times_used INT DEFAULT 0,

  -- Dietary info
  dietary_restrictions TEXT[], -- ['vegetarian', 'gluten_free', 'dairy_free']
  prep_time_minutes INT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_meal_templates_user ON meal_plan_templates(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_templates_day_type ON meal_plan_templates(user_id, day_type);
CREATE INDEX IF NOT EXISTS idx_meal_templates_favorite ON meal_plan_templates(user_id, is_favorite) WHERE is_favorite = true;

COMMENT ON TABLE meal_plan_templates IS 'Reusable meal plan templates for quick planning';

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE weekly_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_plan_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_templates ENABLE ROW LEVEL SECURITY;

-- Weekly plans: users can only access their own plans
CREATE POLICY weekly_plans_select_policy ON weekly_plans
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY weekly_plans_insert_policy ON weekly_plans
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY weekly_plans_update_policy ON weekly_plans
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY weekly_plans_delete_policy ON weekly_plans
  FOR DELETE USING (user_id = auth.uid());

-- Daily plan entries: users can access entries for their own weekly plans
CREATE POLICY daily_plan_entries_select_policy ON daily_plan_entries
  FOR SELECT USING (
    weekly_plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

CREATE POLICY daily_plan_entries_insert_policy ON daily_plan_entries
  FOR INSERT WITH CHECK (
    weekly_plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

CREATE POLICY daily_plan_entries_update_policy ON daily_plan_entries
  FOR UPDATE USING (
    weekly_plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

CREATE POLICY daily_plan_entries_delete_policy ON daily_plan_entries
  FOR DELETE USING (
    weekly_plan_id IN (SELECT id FROM weekly_plans WHERE user_id = auth.uid())
  );

-- Meal plan templates: users can only access their own templates
CREATE POLICY meal_templates_select_policy ON meal_plan_templates
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY meal_templates_insert_policy ON meal_plan_templates
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY meal_templates_update_policy ON meal_plan_templates
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY meal_templates_delete_policy ON meal_plan_templates
  FOR DELETE USING (user_id = auth.uid());

-- ============================================================================
-- SERVICE ROLE POLICIES (for backend API access)
-- ============================================================================

-- Allow service role full access to weekly_plans
CREATE POLICY weekly_plans_service_policy ON weekly_plans
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Allow service role full access to daily_plan_entries
CREATE POLICY daily_plan_entries_service_policy ON daily_plan_entries
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Allow service role full access to meal_plan_templates
CREATE POLICY meal_templates_service_policy ON meal_plan_templates
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- TRIGGER FOR updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_weekly_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER weekly_plans_updated_at_trigger
  BEFORE UPDATE ON weekly_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_weekly_plans_updated_at();

CREATE TRIGGER daily_plan_entries_updated_at_trigger
  BEFORE UPDATE ON daily_plan_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_weekly_plans_updated_at();

CREATE TRIGGER meal_templates_updated_at_trigger
  BEFORE UPDATE ON meal_plan_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_weekly_plans_updated_at();

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- View to get current week's plan with daily entries
CREATE OR REPLACE VIEW current_week_plan_view AS
SELECT
  wp.*,
  COALESCE(
    json_agg(
      json_build_object(
        'id', dpe.id,
        'plan_date', dpe.plan_date,
        'day_type', dpe.day_type,
        'workout_id', dpe.workout_id,
        'workout_time', dpe.workout_time,
        'calorie_target', dpe.calorie_target,
        'protein_target_g', dpe.protein_target_g,
        'carbs_target_g', dpe.carbs_target_g,
        'fat_target_g', dpe.fat_target_g,
        'eating_window_start', dpe.eating_window_start,
        'eating_window_end', dpe.eating_window_end,
        'meal_suggestions', dpe.meal_suggestions,
        'coordination_notes', dpe.coordination_notes
      ) ORDER BY dpe.plan_date
    ) FILTER (WHERE dpe.id IS NOT NULL),
    '[]'::json
  ) as daily_entries
FROM weekly_plans wp
LEFT JOIN daily_plan_entries dpe ON dpe.weekly_plan_id = wp.id
WHERE wp.week_start_date = date_trunc('week', CURRENT_DATE)::date
  AND wp.status = 'active'
GROUP BY wp.id;

COMMENT ON VIEW current_week_plan_view IS 'Current week plan with all daily entries';
