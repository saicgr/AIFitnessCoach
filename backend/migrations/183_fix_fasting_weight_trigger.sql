-- ============================================================================
-- Migration 183: Fix Fasting Weight Correlation Trigger
-- ============================================================================
-- Fixes the trigger that uses non-existent 'workout_type' column.
-- The workouts table uses 'type' not 'workout_type'.
-- ============================================================================

-- Drop and recreate the trigger function with corrected column name
CREATE OR REPLACE FUNCTION update_fasting_weight_correlation()
RETURNS TRIGGER AS $$
DECLARE
  v_fasting_record fasting_records%ROWTYPE;
  v_is_fasting_day BOOLEAN;
  v_days_since_last_fast INTEGER;
  v_workout_completed BOOLEAN;
  v_workout_type TEXT;
BEGIN
  -- Check if user fasted on this day
  SELECT * INTO v_fasting_record
  FROM fasting_records
  WHERE user_id = NEW.user_id
    AND DATE(start_time) = DATE(NEW.logged_at)
    AND status = 'completed'
  ORDER BY start_time DESC
  LIMIT 1;

  v_is_fasting_day := v_fasting_record.id IS NOT NULL;

  -- Calculate days since last fast
  SELECT COALESCE(DATE(NEW.logged_at) - MAX(DATE(start_time)), 999) INTO v_days_since_last_fast
  FROM fasting_records
  WHERE user_id = NEW.user_id
    AND status = 'completed'
    AND DATE(start_time) < DATE(NEW.logged_at);

  -- Check if workout was completed on this day
  -- FIXED: Use 'type' column instead of non-existent 'workout_type'
  SELECT
    COUNT(*) > 0,
    MAX(type)  -- Changed from workout_type to type
  INTO v_workout_completed, v_workout_type
  FROM workouts
  WHERE user_id = NEW.user_id
    AND DATE(created_at) = DATE(NEW.logged_at)
    AND is_completed = true;

  -- Upsert into fasting_weight_correlation
  INSERT INTO fasting_weight_correlation (
    user_id,
    date,
    weight_kg,
    weight_logged_at,
    is_fasting_day,
    fasting_record_id,
    fasting_protocol,
    fasting_duration_minutes,
    fasting_completed_goal,
    days_since_last_fast,
    workout_completed_that_day,
    workout_type
  )
  VALUES (
    NEW.user_id,
    DATE(NEW.logged_at),
    NEW.weight_kg,
    NEW.logged_at,
    v_is_fasting_day,
    v_fasting_record.id,
    v_fasting_record.protocol,
    COALESCE(v_fasting_record.actual_duration_minutes, 0),
    COALESCE(v_fasting_record.completed_goal, false),
    COALESCE(v_days_since_last_fast, 999),
    COALESCE(v_workout_completed, false),
    v_workout_type
  )
  ON CONFLICT (user_id, date)
  DO UPDATE SET
    weight_kg = EXCLUDED.weight_kg,
    weight_logged_at = EXCLUDED.weight_logged_at,
    is_fasting_day = EXCLUDED.is_fasting_day,
    fasting_record_id = EXCLUDED.fasting_record_id,
    fasting_protocol = EXCLUDED.fasting_protocol,
    fasting_duration_minutes = EXCLUDED.fasting_duration_minutes,
    fasting_completed_goal = EXCLUDED.fasting_completed_goal,
    days_since_last_fast = EXCLUDED.days_since_last_fast,
    workout_completed_that_day = EXCLUDED.workout_completed_that_day,
    workout_type = EXCLUDED.workout_type;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comment on the fix
COMMENT ON FUNCTION update_fasting_weight_correlation IS 'Automatically updates fasting_weight_correlation table when new weight is logged. Fixed to use type column instead of workout_type.';
