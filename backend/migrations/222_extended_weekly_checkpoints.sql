-- Migration 222: Extended Weekly Checkpoints
-- Adds tracking for all weekly checkpoints from XP_SYSTEM_GUIDE.md:
-- Weekly Protein, Calories, Hydration, Weight, Habits, Streak, Social, Measurements

-- =====================================================
-- 1. Extend checkpoint_progress table with new metrics
-- =====================================================

-- Add new columns for weekly metric tracking
ALTER TABLE IF EXISTS user_checkpoint_progress
ADD COLUMN IF NOT EXISTS protein_days INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS protein_target INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS protein_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS calorie_days INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS calorie_target INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS calorie_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS hydration_days INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS hydration_target INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS hydration_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS weight_logs INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS weight_target INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS weight_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS habit_percent NUMERIC(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS habit_target INTEGER DEFAULT 70,
ADD COLUMN IF NOT EXISTS habit_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS workout_streak INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS workout_streak_target INTEGER DEFAULT 7,
ADD COLUMN IF NOT EXISTS workout_streak_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS social_engagements INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS social_target INTEGER DEFAULT 5,
ADD COLUMN IF NOT EXISTS social_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS measurement_logs INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS measurement_target INTEGER DEFAULT 2,
ADD COLUMN IF NOT EXISTS measurement_complete BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS perfect_week BOOLEAN DEFAULT FALSE;

-- =====================================================
-- 2. Create weekly checkpoint XP values
-- =====================================================

-- Table to store checkpoint XP reward configuration
CREATE TABLE IF NOT EXISTS checkpoint_rewards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  checkpoint_type TEXT NOT NULL, -- 'weekly' or 'monthly'
  metric_name TEXT NOT NULL, -- 'workouts', 'protein', 'calories', etc.
  xp_reward INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert weekly checkpoint rewards
INSERT INTO checkpoint_rewards (checkpoint_type, metric_name, xp_reward) VALUES
  ('weekly', 'workouts', 200),
  ('weekly', 'perfect_week', 500),
  ('weekly', 'protein', 150),
  ('weekly', 'calories', 150),
  ('weekly', 'hydration', 100),
  ('weekly', 'weight', 75),
  ('weekly', 'habits', 100),
  ('weekly', 'workout_streak', 100),
  ('weekly', 'social', 150),
  ('weekly', 'measurements', 50)
ON CONFLICT DO NOTHING;

-- =====================================================
-- 3. Function to increment protein day
-- =====================================================

CREATE OR REPLACE FUNCTION increment_weekly_protein(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
BEGIN
  -- Get current week start (Monday)
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  -- Get or create weekly record
  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    -- Initialize weekly record
    PERFORM init_user_checkpoint_progress(p_user_id);
    SELECT * INTO v_current_record
    FROM user_checkpoint_progress
    WHERE user_id = p_user_id
      AND checkpoint_type = 'weekly'
      AND period_start = v_week_start;
  END IF;

  -- Only increment if not already complete
  IF NOT v_current_record.protein_complete THEN
    UPDATE user_checkpoint_progress
    SET protein_days = protein_days + 1,
        protein_complete = (protein_days + 1) >= protein_target,
        updated_at = NOW()
    WHERE id = v_current_record.id
    RETURNING * INTO v_current_record;

    -- Award XP if just completed
    IF v_current_record.protein_complete AND NOT v_current_record.protein_complete THEN
      v_xp_awarded := 150;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'weekly_protein', NULL,
        'Weekly protein goal complete (' || v_current_record.protein_target || ' days)');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'protein_days', v_current_record.protein_days,
    'protein_target', v_current_record.protein_target,
    'protein_complete', v_current_record.protein_complete,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 4. Function to increment calorie day
-- =====================================================

CREATE OR REPLACE FUNCTION increment_weekly_calories(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    PERFORM init_user_checkpoint_progress(p_user_id);
    SELECT * INTO v_current_record
    FROM user_checkpoint_progress
    WHERE user_id = p_user_id
      AND checkpoint_type = 'weekly'
      AND period_start = v_week_start;
  END IF;

  IF NOT v_current_record.calorie_complete THEN
    UPDATE user_checkpoint_progress
    SET calorie_days = calorie_days + 1,
        calorie_complete = (calorie_days + 1) >= calorie_target,
        updated_at = NOW()
    WHERE id = v_current_record.id
    RETURNING * INTO v_current_record;

    IF v_current_record.calorie_complete THEN
      v_xp_awarded := 150;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'weekly_calories', NULL,
        'Weekly calorie goal complete (' || v_current_record.calorie_target || ' days)');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'calorie_days', v_current_record.calorie_days,
    'calorie_target', v_current_record.calorie_target,
    'calorie_complete', v_current_record.calorie_complete,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 5. Function to increment hydration day
-- =====================================================

CREATE OR REPLACE FUNCTION increment_weekly_hydration(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    PERFORM init_user_checkpoint_progress(p_user_id);
    SELECT * INTO v_current_record
    FROM user_checkpoint_progress
    WHERE user_id = p_user_id
      AND checkpoint_type = 'weekly'
      AND period_start = v_week_start;
  END IF;

  IF NOT v_current_record.hydration_complete THEN
    UPDATE user_checkpoint_progress
    SET hydration_days = hydration_days + 1,
        hydration_complete = (hydration_days + 1) >= hydration_target,
        updated_at = NOW()
    WHERE id = v_current_record.id
    RETURNING * INTO v_current_record;

    IF v_current_record.hydration_complete THEN
      v_xp_awarded := 100;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'weekly_hydration', NULL,
        'Weekly hydration goal complete (' || v_current_record.hydration_target || ' days)');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'hydration_days', v_current_record.hydration_days,
    'hydration_target', v_current_record.hydration_target,
    'hydration_complete', v_current_record.hydration_complete,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 6. Function to increment weight log
-- =====================================================

CREATE OR REPLACE FUNCTION increment_weekly_weight(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    PERFORM init_user_checkpoint_progress(p_user_id);
    SELECT * INTO v_current_record
    FROM user_checkpoint_progress
    WHERE user_id = p_user_id
      AND checkpoint_type = 'weekly'
      AND period_start = v_week_start;
  END IF;

  IF NOT v_current_record.weight_complete THEN
    UPDATE user_checkpoint_progress
    SET weight_logs = weight_logs + 1,
        weight_complete = (weight_logs + 1) >= weight_target,
        updated_at = NOW()
    WHERE id = v_current_record.id
    RETURNING * INTO v_current_record;

    IF v_current_record.weight_complete THEN
      v_xp_awarded := 75;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'weekly_weight', NULL,
        'Weekly weight logging complete (' || v_current_record.weight_target || '+ logs)');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'weight_logs', v_current_record.weight_logs,
    'weight_target', v_current_record.weight_target,
    'weight_complete', v_current_record.weight_complete,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 7. Function to update habit completion percentage
-- =====================================================

CREATE OR REPLACE FUNCTION update_weekly_habits(p_user_id UUID, p_completion_percent NUMERIC)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
  v_was_complete BOOLEAN;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    PERFORM init_user_checkpoint_progress(p_user_id);
    SELECT * INTO v_current_record
    FROM user_checkpoint_progress
    WHERE user_id = p_user_id
      AND checkpoint_type = 'weekly'
      AND period_start = v_week_start;
  END IF;

  v_was_complete := v_current_record.habit_complete;

  UPDATE user_checkpoint_progress
  SET habit_percent = p_completion_percent,
      habit_complete = p_completion_percent >= habit_target,
      updated_at = NOW()
  WHERE id = v_current_record.id
  RETURNING * INTO v_current_record;

  IF v_current_record.habit_complete AND NOT v_was_complete THEN
    v_xp_awarded := 100;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'weekly_habits', NULL,
      'Weekly habit completion (' || v_current_record.habit_target || '%+)');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'habit_percent', v_current_record.habit_percent,
    'habit_target', v_current_record.habit_target,
    'habit_complete', v_current_record.habit_complete,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 8. Function to increment social engagement
-- =====================================================

CREATE OR REPLACE FUNCTION increment_weekly_social(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    PERFORM init_user_checkpoint_progress(p_user_id);
    SELECT * INTO v_current_record
    FROM user_checkpoint_progress
    WHERE user_id = p_user_id
      AND checkpoint_type = 'weekly'
      AND period_start = v_week_start;
  END IF;

  IF NOT v_current_record.social_complete THEN
    UPDATE user_checkpoint_progress
    SET social_engagements = social_engagements + 1,
        social_complete = (social_engagements + 1) >= social_target,
        updated_at = NOW()
    WHERE id = v_current_record.id
    RETURNING * INTO v_current_record;

    IF v_current_record.social_complete THEN
      v_xp_awarded := 150;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'weekly_social', NULL,
        'Weekly social goal complete (' || v_current_record.social_target || ' engagements)');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'social_engagements', v_current_record.social_engagements,
    'social_target', v_current_record.social_target,
    'social_complete', v_current_record.social_complete,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 9. Function to increment measurement log
-- =====================================================

CREATE OR REPLACE FUNCTION increment_weekly_measurements(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    PERFORM init_user_checkpoint_progress(p_user_id);
    SELECT * INTO v_current_record
    FROM user_checkpoint_progress
    WHERE user_id = p_user_id
      AND checkpoint_type = 'weekly'
      AND period_start = v_week_start;
  END IF;

  IF NOT v_current_record.measurement_complete THEN
    UPDATE user_checkpoint_progress
    SET measurement_logs = measurement_logs + 1,
        measurement_complete = (measurement_logs + 1) >= measurement_target,
        updated_at = NOW()
    WHERE id = v_current_record.id
    RETURNING * INTO v_current_record;

    IF v_current_record.measurement_complete THEN
      v_xp_awarded := 50;
      PERFORM award_xp(p_user_id, v_xp_awarded, 'weekly_measurements', NULL,
        'Weekly measurements complete (' || v_current_record.measurement_target || ' logs)');
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'measurement_logs', v_current_record.measurement_logs,
    'measurement_target', v_current_record.measurement_target,
    'measurement_complete', v_current_record.measurement_complete,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 10. Function to check/award perfect week
-- =====================================================

CREATE OR REPLACE FUNCTION check_perfect_week(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_record user_checkpoint_progress%ROWTYPE;
  v_days_per_week INTEGER;
  v_xp_awarded INTEGER := 0;
  v_week_start DATE;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;

  -- Get user's scheduled days per week
  v_days_per_week := get_user_days_per_week(p_user_id);

  SELECT * INTO v_current_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_current_record.id IS NULL THEN
    RETURN jsonb_build_object('success', FALSE, 'message', 'No weekly record found');
  END IF;

  -- Check if user completed all scheduled workouts
  IF v_current_record.workouts_completed >= v_days_per_week AND NOT v_current_record.perfect_week THEN
    UPDATE user_checkpoint_progress
    SET perfect_week = TRUE,
        updated_at = NOW()
    WHERE id = v_current_record.id;

    v_xp_awarded := 500;
    PERFORM award_xp(p_user_id, v_xp_awarded, 'perfect_week', NULL,
      'Perfect Week - completed all ' || v_days_per_week || ' scheduled workouts!');
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'perfect_week', v_current_record.perfect_week OR (v_current_record.workouts_completed >= v_days_per_week),
    'workouts_completed', v_current_record.workouts_completed,
    'scheduled_workouts', v_days_per_week,
    'xp_awarded', v_xp_awarded
  );
END;
$$;

-- =====================================================
-- 11. Function to get full weekly checkpoint progress
-- =====================================================

CREATE OR REPLACE FUNCTION get_full_weekly_progress(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_record user_checkpoint_progress%ROWTYPE;
  v_week_start DATE;
  v_days_per_week INTEGER;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;
  v_days_per_week := get_user_days_per_week(p_user_id);

  SELECT * INTO v_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_record.id IS NULL THEN
    -- Return empty progress
    RETURN jsonb_build_object(
      'period_start', v_week_start,
      'period_end', v_week_start + INTERVAL '6 days',
      'days_per_week', v_days_per_week,
      'checkpoints', jsonb_build_array(
        jsonb_build_object('name', 'workouts', 'current', 0, 'target', v_days_per_week, 'complete', FALSE, 'xp', 200),
        jsonb_build_object('name', 'perfect_week', 'current', 0, 'target', v_days_per_week, 'complete', FALSE, 'xp', 500),
        jsonb_build_object('name', 'protein', 'current', 0, 'target', 5, 'complete', FALSE, 'xp', 150),
        jsonb_build_object('name', 'calories', 'current', 0, 'target', 5, 'complete', FALSE, 'xp', 150),
        jsonb_build_object('name', 'hydration', 'current', 0, 'target', 5, 'complete', FALSE, 'xp', 100),
        jsonb_build_object('name', 'weight', 'current', 0, 'target', 3, 'complete', FALSE, 'xp', 75),
        jsonb_build_object('name', 'habits', 'current', 0, 'target', 70, 'complete', FALSE, 'xp', 100),
        jsonb_build_object('name', 'workout_streak', 'current', 0, 'target', 7, 'complete', FALSE, 'xp', 100),
        jsonb_build_object('name', 'social', 'current', 0, 'target', 5, 'complete', FALSE, 'xp', 150),
        jsonb_build_object('name', 'measurements', 'current', 0, 'target', 2, 'complete', FALSE, 'xp', 50)
      ),
      'total_xp_available', 1575,
      'total_xp_earned', 0
    );
  END IF;

  RETURN jsonb_build_object(
    'period_start', v_record.period_start,
    'period_end', v_record.period_end,
    'days_per_week', v_days_per_week,
    'checkpoints', jsonb_build_array(
      jsonb_build_object('name', 'workouts', 'current', v_record.workouts_completed, 'target', v_record.workouts_target, 'complete', v_record.xp_awarded, 'xp', 200),
      jsonb_build_object('name', 'perfect_week', 'current', v_record.workouts_completed, 'target', v_days_per_week, 'complete', v_record.perfect_week, 'xp', 500),
      jsonb_build_object('name', 'protein', 'current', v_record.protein_days, 'target', v_record.protein_target, 'complete', v_record.protein_complete, 'xp', 150),
      jsonb_build_object('name', 'calories', 'current', v_record.calorie_days, 'target', v_record.calorie_target, 'complete', v_record.calorie_complete, 'xp', 150),
      jsonb_build_object('name', 'hydration', 'current', v_record.hydration_days, 'target', v_record.hydration_target, 'complete', v_record.hydration_complete, 'xp', 100),
      jsonb_build_object('name', 'weight', 'current', v_record.weight_logs, 'target', v_record.weight_target, 'complete', v_record.weight_complete, 'xp', 75),
      jsonb_build_object('name', 'habits', 'current', v_record.habit_percent, 'target', v_record.habit_target, 'complete', v_record.habit_complete, 'xp', 100),
      jsonb_build_object('name', 'workout_streak', 'current', v_record.workout_streak, 'target', v_record.workout_streak_target, 'complete', v_record.workout_streak_complete, 'xp', 100),
      jsonb_build_object('name', 'social', 'current', v_record.social_engagements, 'target', v_record.social_target, 'complete', v_record.social_complete, 'xp', 150),
      jsonb_build_object('name', 'measurements', 'current', v_record.measurement_logs, 'target', v_record.measurement_target, 'complete', v_record.measurement_complete, 'xp', 50)
    ),
    'total_xp_available', 1575,
    'total_xp_earned',
      CASE WHEN v_record.xp_awarded THEN 200 ELSE 0 END +
      CASE WHEN v_record.perfect_week THEN 500 ELSE 0 END +
      CASE WHEN v_record.protein_complete THEN 150 ELSE 0 END +
      CASE WHEN v_record.calorie_complete THEN 150 ELSE 0 END +
      CASE WHEN v_record.hydration_complete THEN 100 ELSE 0 END +
      CASE WHEN v_record.weight_complete THEN 75 ELSE 0 END +
      CASE WHEN v_record.habit_complete THEN 100 ELSE 0 END +
      CASE WHEN v_record.workout_streak_complete THEN 100 ELSE 0 END +
      CASE WHEN v_record.social_complete THEN 150 ELSE 0 END +
      CASE WHEN v_record.measurement_complete THEN 50 ELSE 0 END
  );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION increment_weekly_protein(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_weekly_calories(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_weekly_hydration(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_weekly_weight(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_weekly_habits(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_weekly_social(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION increment_weekly_measurements(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION check_perfect_week(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_full_weekly_progress(UUID) TO authenticated;
