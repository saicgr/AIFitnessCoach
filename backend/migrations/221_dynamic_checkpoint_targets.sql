-- ============================================================================
-- Migration 221: Dynamic Checkpoint Targets Based on User's Days Per Week
-- ============================================================================
-- This migration updates the checkpoint progress functions to use dynamic
-- targets based on each user's selected workout days per week instead of
-- hardcoded values (5 weekly, 20 monthly).
--
-- Formula:
-- - Weekly target = days_per_week
-- - Monthly target = CEIL(days_per_week * 4.3)
-- ============================================================================

-- ============================================================================
-- Helper Function: Get user's days per week from preferences
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_days_per_week(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_preferences JSONB;
  v_workout_days JSONB;
  v_days_per_week INTEGER;
BEGIN
  -- Get user preferences
  SELECT preferences INTO v_preferences
  FROM users WHERE id = p_user_id;

  -- If no preferences, return default
  IF v_preferences IS NULL THEN
    RETURN 5;
  END IF;

  -- Try workouts_per_week first (explicit setting)
  v_days_per_week := (v_preferences->>'workouts_per_week')::INTEGER;

  -- If not set, count workout_days array
  IF v_days_per_week IS NULL THEN
    v_workout_days := v_preferences->'workout_days';
    IF v_workout_days IS NOT NULL AND jsonb_typeof(v_workout_days) = 'array' AND jsonb_array_length(v_workout_days) > 0 THEN
      v_days_per_week := jsonb_array_length(v_workout_days);
    ELSE
      v_days_per_week := 5; -- Default fallback
    END IF;
  END IF;

  -- Clamp to valid range (1-7)
  RETURN GREATEST(1, LEAST(7, v_days_per_week));
END;
$$;

COMMENT ON FUNCTION get_user_days_per_week IS 'Get user workout days per week from preferences (default: 5)';

-- ============================================================================
-- Updated Function: Initialize or get current checkpoint progress with DYNAMIC targets
-- ============================================================================
CREATE OR REPLACE FUNCTION init_user_checkpoint_progress(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_week_start DATE;
  v_week_end DATE;
  v_month_start DATE;
  v_month_end DATE;
  v_weekly_record user_checkpoint_progress%ROWTYPE;
  v_monthly_record user_checkpoint_progress%ROWTYPE;
  v_days_per_week INTEGER;
  v_weekly_target INTEGER;
  v_monthly_target INTEGER;
BEGIN
  -- Get user's days per week for DYNAMIC targets
  v_days_per_week := get_user_days_per_week(p_user_id);
  v_weekly_target := v_days_per_week;
  v_monthly_target := CEIL(v_days_per_week * 4.3)::INTEGER;

  -- Calculate current week (Monday to Sunday)
  v_week_start := v_today - EXTRACT(DOW FROM v_today)::INTEGER + 1;
  IF EXTRACT(DOW FROM v_today) = 0 THEN
    v_week_start := v_week_start - 7; -- Sunday belongs to previous week's period
  END IF;
  v_week_end := v_week_start + 6;

  -- Calculate current month
  v_month_start := DATE_TRUNC('month', v_today)::DATE;
  v_month_end := (DATE_TRUNC('month', v_today) + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  -- Initialize or get weekly checkpoint with DYNAMIC target
  INSERT INTO user_checkpoint_progress (
    user_id, checkpoint_type, period_start, period_end, workouts_target
  ) VALUES (
    p_user_id, 'weekly', v_week_start, v_week_end, v_weekly_target
  )
  ON CONFLICT (user_id, checkpoint_type, period_start) DO NOTHING;

  SELECT * INTO v_weekly_record FROM user_checkpoint_progress
  WHERE user_id = p_user_id AND checkpoint_type = 'weekly' AND period_start = v_week_start;

  -- Initialize or get monthly checkpoint with DYNAMIC target
  INSERT INTO user_checkpoint_progress (
    user_id, checkpoint_type, period_start, period_end, workouts_target
  ) VALUES (
    p_user_id, 'monthly', v_month_start, v_month_end, v_monthly_target
  )
  ON CONFLICT (user_id, checkpoint_type, period_start) DO NOTHING;

  SELECT * INTO v_monthly_record FROM user_checkpoint_progress
  WHERE user_id = p_user_id AND checkpoint_type = 'monthly' AND period_start = v_month_start;

  RETURN jsonb_build_object(
    'weekly', jsonb_build_object(
      'period_start', v_week_start,
      'period_end', v_week_end,
      'workouts_target', v_weekly_record.workouts_target,
      'workouts_completed', v_weekly_record.workouts_completed,
      'xp_awarded', v_weekly_record.xp_awarded,
      'progress_percent', LEAST(100, (v_weekly_record.workouts_completed::FLOAT / v_weekly_record.workouts_target * 100)::INTEGER),
      'days_per_week', v_days_per_week
    ),
    'monthly', jsonb_build_object(
      'period_start', v_month_start,
      'period_end', v_month_end,
      'workouts_target', v_monthly_record.workouts_target,
      'workouts_completed', v_monthly_record.workouts_completed,
      'xp_awarded', v_monthly_record.xp_awarded,
      'progress_percent', LEAST(100, (v_monthly_record.workouts_completed::FLOAT / v_monthly_record.workouts_target * 100)::INTEGER),
      'days_per_week', v_days_per_week
    )
  );
END;
$$;

-- ============================================================================
-- Updated Function: Increment workout count with DYNAMIC target descriptions
-- ============================================================================
CREATE OR REPLACE FUNCTION increment_checkpoint_workout(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_today DATE := CURRENT_DATE;
  v_week_start DATE;
  v_month_start DATE;
  v_weekly_xp_awarded INTEGER := 0;
  v_monthly_xp_awarded INTEGER := 0;
  v_weekly_record user_checkpoint_progress%ROWTYPE;
  v_monthly_record user_checkpoint_progress%ROWTYPE;
  v_days_per_week INTEGER;
BEGIN
  -- Get user's days per week for dynamic descriptions
  v_days_per_week := get_user_days_per_week(p_user_id);

  -- Calculate current periods
  v_week_start := v_today - EXTRACT(DOW FROM v_today)::INTEGER + 1;
  IF EXTRACT(DOW FROM v_today) = 0 THEN
    v_week_start := v_week_start - 7;
  END IF;
  v_month_start := DATE_TRUNC('month', v_today)::DATE;

  -- Ensure checkpoint records exist (with dynamic targets)
  PERFORM init_user_checkpoint_progress(p_user_id);

  -- Increment weekly workout count
  UPDATE user_checkpoint_progress
  SET workouts_completed = workouts_completed + 1,
      updated_at = NOW()
  WHERE user_id = p_user_id AND checkpoint_type = 'weekly' AND period_start = v_week_start;

  -- Check if weekly goal is now complete
  SELECT * INTO v_weekly_record FROM user_checkpoint_progress
  WHERE user_id = p_user_id AND checkpoint_type = 'weekly' AND period_start = v_week_start;

  IF v_weekly_record.workouts_completed >= v_weekly_record.workouts_target
     AND NOT v_weekly_record.xp_awarded THEN
    -- Award weekly XP (200 XP)
    v_weekly_xp_awarded := 200;
    UPDATE user_checkpoint_progress
    SET xp_awarded = TRUE, awarded_at = NOW()
    WHERE id = v_weekly_record.id;

    -- Award XP to user with DYNAMIC description
    PERFORM award_xp(p_user_id, v_weekly_xp_awarded, 'checkpoint', 'weekly_complete',
                     format('Weekly workout goal complete (%s workouts)', v_weekly_record.workouts_target), FALSE);
  END IF;

  -- Increment monthly workout count
  UPDATE user_checkpoint_progress
  SET workouts_completed = workouts_completed + 1,
      updated_at = NOW()
  WHERE user_id = p_user_id AND checkpoint_type = 'monthly' AND period_start = v_month_start;

  -- Check if monthly goal is now complete
  SELECT * INTO v_monthly_record FROM user_checkpoint_progress
  WHERE user_id = p_user_id AND checkpoint_type = 'monthly' AND period_start = v_month_start;

  IF v_monthly_record.workouts_completed >= v_monthly_record.workouts_target
     AND NOT v_monthly_record.xp_awarded THEN
    -- Award monthly XP (1000 XP)
    v_monthly_xp_awarded := 1000;
    UPDATE user_checkpoint_progress
    SET xp_awarded = TRUE, awarded_at = NOW()
    WHERE id = v_monthly_record.id;

    -- Award XP to user with DYNAMIC description
    PERFORM award_xp(p_user_id, v_monthly_xp_awarded, 'checkpoint', 'monthly_complete',
                     format('Monthly workout goal complete (%s workouts)', v_monthly_record.workouts_target), FALSE);
  END IF;

  RETURN jsonb_build_object(
    'weekly_xp_awarded', v_weekly_xp_awarded,
    'monthly_xp_awarded', v_monthly_xp_awarded,
    'weekly_workouts', v_weekly_record.workouts_completed,
    'monthly_workouts', v_monthly_record.workouts_completed,
    'weekly_target', v_weekly_record.workouts_target,
    'monthly_target', v_monthly_record.workouts_target,
    'weekly_complete', v_weekly_record.workouts_completed >= v_weekly_record.workouts_target,
    'monthly_complete', v_monthly_record.workouts_completed >= v_monthly_record.workouts_target,
    'days_per_week', v_days_per_week
  );
END;
$$;

-- Add comments
COMMENT ON FUNCTION init_user_checkpoint_progress IS 'Initialize checkpoint progress with DYNAMIC targets based on user days_per_week';
COMMENT ON FUNCTION increment_checkpoint_workout IS 'Increment workout count for checkpoints with DYNAMIC target descriptions';
