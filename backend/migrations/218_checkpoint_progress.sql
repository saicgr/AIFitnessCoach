-- ============================================================================
-- Migration 218: Weekly/Monthly Checkpoint Progress System
-- ============================================================================
-- This migration creates the user_checkpoint_progress table to track
-- weekly and monthly workout checkpoint progress.
-- ============================================================================

-- Create the user_checkpoint_progress table
CREATE TABLE IF NOT EXISTS user_checkpoint_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  checkpoint_type VARCHAR(20) NOT NULL CHECK (checkpoint_type IN ('weekly', 'monthly')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  workouts_target INTEGER NOT NULL,
  workouts_completed INTEGER DEFAULT 0,
  xp_awarded BOOLEAN DEFAULT FALSE,
  awarded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Each user can only have one record per checkpoint type per period
  UNIQUE(user_id, checkpoint_type, period_start)
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_checkpoint_progress_user_id
ON user_checkpoint_progress(user_id);

CREATE INDEX IF NOT EXISTS idx_user_checkpoint_progress_type_date
ON user_checkpoint_progress(checkpoint_type, period_start);

CREATE INDEX IF NOT EXISTS idx_user_checkpoint_progress_not_awarded
ON user_checkpoint_progress(user_id, checkpoint_type) WHERE xp_awarded = FALSE;

-- Enable Row Level Security
ALTER TABLE user_checkpoint_progress ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own progress
DROP POLICY IF EXISTS "Users can view own checkpoint progress" ON user_checkpoint_progress;
CREATE POLICY "Users can view own checkpoint progress"
ON user_checkpoint_progress
FOR SELECT
USING (user_id = auth.uid());

-- RLS Policy: Service role can manage all progress
DROP POLICY IF EXISTS "Service can manage checkpoint progress" ON user_checkpoint_progress;
CREATE POLICY "Service can manage checkpoint progress"
ON user_checkpoint_progress
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant access
GRANT SELECT ON user_checkpoint_progress TO authenticated;
GRANT ALL ON user_checkpoint_progress TO service_role;

-- ============================================================================
-- Function to initialize or get current checkpoint progress for a user
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
BEGIN
  -- Calculate current week (Monday to Sunday)
  v_week_start := v_today - EXTRACT(DOW FROM v_today)::INTEGER + 1;
  IF EXTRACT(DOW FROM v_today) = 0 THEN
    v_week_start := v_week_start - 7; -- Sunday belongs to previous week's period
  END IF;
  v_week_end := v_week_start + 6;

  -- Calculate current month
  v_month_start := DATE_TRUNC('month', v_today)::DATE;
  v_month_end := (DATE_TRUNC('month', v_today) + INTERVAL '1 month' - INTERVAL '1 day')::DATE;

  -- Initialize or get weekly checkpoint
  INSERT INTO user_checkpoint_progress (
    user_id, checkpoint_type, period_start, period_end, workouts_target
  ) VALUES (
    p_user_id, 'weekly', v_week_start, v_week_end, 5
  )
  ON CONFLICT (user_id, checkpoint_type, period_start) DO NOTHING;

  SELECT * INTO v_weekly_record FROM user_checkpoint_progress
  WHERE user_id = p_user_id AND checkpoint_type = 'weekly' AND period_start = v_week_start;

  -- Initialize or get monthly checkpoint
  INSERT INTO user_checkpoint_progress (
    user_id, checkpoint_type, period_start, period_end, workouts_target
  ) VALUES (
    p_user_id, 'monthly', v_month_start, v_month_end, 20
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
      'progress_percent', LEAST(100, (v_weekly_record.workouts_completed::FLOAT / v_weekly_record.workouts_target * 100)::INTEGER)
    ),
    'monthly', jsonb_build_object(
      'period_start', v_month_start,
      'period_end', v_month_end,
      'workouts_target', v_monthly_record.workouts_target,
      'workouts_completed', v_monthly_record.workouts_completed,
      'xp_awarded', v_monthly_record.xp_awarded,
      'progress_percent', LEAST(100, (v_monthly_record.workouts_completed::FLOAT / v_monthly_record.workouts_target * 100)::INTEGER)
    )
  );
END;
$$;

-- ============================================================================
-- Function to increment workout count and check for XP awards
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
BEGIN
  -- Calculate current periods
  v_week_start := v_today - EXTRACT(DOW FROM v_today)::INTEGER + 1;
  IF EXTRACT(DOW FROM v_today) = 0 THEN
    v_week_start := v_week_start - 7;
  END IF;
  v_month_start := DATE_TRUNC('month', v_today)::DATE;

  -- Ensure checkpoint records exist
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

    -- Award XP to user
    PERFORM award_xp(p_user_id, v_weekly_xp_awarded, 'checkpoint', 'weekly_complete',
                     'Weekly workout goal complete (5 workouts)', FALSE);
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

    -- Award XP to user
    PERFORM award_xp(p_user_id, v_monthly_xp_awarded, 'checkpoint', 'monthly_complete',
                     'Monthly workout goal complete (20 workouts)', FALSE);
  END IF;

  RETURN jsonb_build_object(
    'weekly_xp_awarded', v_weekly_xp_awarded,
    'monthly_xp_awarded', v_monthly_xp_awarded,
    'weekly_workouts', v_weekly_record.workouts_completed + 1, -- +1 because we updated
    'monthly_workouts', v_monthly_record.workouts_completed + 1,
    'weekly_complete', v_weekly_record.workouts_completed + 1 >= v_weekly_record.workouts_target,
    'monthly_complete', v_monthly_record.workouts_completed + 1 >= v_monthly_record.workouts_target
  );
END;
$$;

-- Add comments
COMMENT ON TABLE user_checkpoint_progress IS 'Tracks weekly and monthly workout checkpoint progress for XP rewards';
COMMENT ON COLUMN user_checkpoint_progress.checkpoint_type IS 'Type of checkpoint: weekly (5 workouts = 200 XP) or monthly (20 workouts = 1000 XP)';
COMMENT ON COLUMN user_checkpoint_progress.workouts_completed IS 'Number of workouts completed in this period';
COMMENT ON COLUMN user_checkpoint_progress.xp_awarded IS 'Whether XP has been awarded for completing this checkpoint';
