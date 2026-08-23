-- E2E register #360: Weekly "Weight Logging 0/3" and "Body Measurements 0/2"
-- showed zero against 7 real `body_measurements` rows (6 inside the current
-- week). Root cause: `get_full_weekly_progress` (migration 222) reads
-- `user_checkpoint_progress.weight_logs` / `.measurement_logs`, columns only
-- ever bumped by `increment_weekly_weight` / `increment_weekly_measurements`
-- — and nothing in the app calls either RPC, so the columns stay at their
-- DEFAULT 0 forever regardless of how much the user actually logs.
--
-- Fix: compute `weight`/`measurements` current counts LIVE from
-- `body_measurements` (the table the app's own measurement-logging flow
-- writes to) for the current calendar week, instead of trusting the
-- never-incremented stored counters. Every other checkpoint (workouts,
-- protein, calories, hydration, habits, workout_streak, social,
-- perfect_week) is unchanged — this migration only touches the two
-- checkpoints named in the finding.

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
  v_weight_logs INTEGER;
  v_measurement_logs INTEGER;
BEGIN
  v_week_start := date_trunc('week', CURRENT_DATE)::DATE;
  v_days_per_week := get_user_days_per_week(p_user_id);

  -- Live counts from the table the app actually writes measurements to,
  -- rather than the stored-but-never-incremented checkpoint columns.
  SELECT COUNT(*) INTO v_weight_logs
  FROM body_measurements
  WHERE user_id = p_user_id
    AND weight_kg IS NOT NULL
    AND measured_at::date >= v_week_start
    AND measured_at::date < v_week_start + 7;

  SELECT COUNT(*) INTO v_measurement_logs
  FROM body_measurements
  WHERE user_id = p_user_id
    AND measured_at::date >= v_week_start
    AND measured_at::date < v_week_start + 7
    AND (chest_cm IS NOT NULL OR waist_cm IS NOT NULL OR hip_cm IS NOT NULL
         OR neck_cm IS NOT NULL OR bicep_left_cm IS NOT NULL
         OR bicep_right_cm IS NOT NULL OR thigh_left_cm IS NOT NULL
         OR thigh_right_cm IS NOT NULL OR calf_left_cm IS NOT NULL
         OR calf_right_cm IS NOT NULL OR shoulder_cm IS NOT NULL
         OR body_fat_percent IS NOT NULL);

  SELECT * INTO v_record
  FROM user_checkpoint_progress
  WHERE user_id = p_user_id
    AND checkpoint_type = 'weekly'
    AND period_start = v_week_start;

  IF v_record.id IS NULL THEN
    -- Return empty progress (weight/measurements still read live)
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
        jsonb_build_object('name', 'weight', 'current', v_weight_logs, 'target', 3, 'complete', v_weight_logs >= 3, 'xp', 75),
        jsonb_build_object('name', 'habits', 'current', 0, 'target', 70, 'complete', FALSE, 'xp', 100),
        jsonb_build_object('name', 'workout_streak', 'current', 0, 'target', 7, 'complete', FALSE, 'xp', 100),
        jsonb_build_object('name', 'social', 'current', 0, 'target', 5, 'complete', FALSE, 'xp', 150),
        jsonb_build_object('name', 'measurements', 'current', v_measurement_logs, 'target', 2, 'complete', v_measurement_logs >= 2, 'xp', 50)
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
      jsonb_build_object('name', 'weight', 'current', v_weight_logs, 'target', v_record.weight_target, 'complete', v_weight_logs >= v_record.weight_target, 'xp', 75),
      jsonb_build_object('name', 'habits', 'current', v_record.habit_percent, 'target', v_record.habit_target, 'complete', v_record.habit_complete, 'xp', 100),
      jsonb_build_object('name', 'workout_streak', 'current', v_record.workout_streak, 'target', v_record.workout_streak_target, 'complete', v_record.workout_streak_complete, 'xp', 100),
      jsonb_build_object('name', 'social', 'current', v_record.social_engagements, 'target', v_record.social_target, 'complete', v_record.social_complete, 'xp', 150),
      jsonb_build_object('name', 'measurements', 'current', v_measurement_logs, 'target', v_record.measurement_target, 'complete', v_measurement_logs >= v_record.measurement_target, 'xp', 50)
    ),
    'total_xp_available', 1575,
    'total_xp_earned',
      CASE WHEN v_record.xp_awarded THEN 200 ELSE 0 END +
      CASE WHEN v_record.perfect_week THEN 500 ELSE 0 END +
      CASE WHEN v_record.protein_complete THEN 150 ELSE 0 END +
      CASE WHEN v_record.calorie_complete THEN 150 ELSE 0 END +
      CASE WHEN v_record.hydration_complete THEN 100 ELSE 0 END +
      CASE WHEN v_weight_logs >= v_record.weight_target THEN 75 ELSE 0 END +
      CASE WHEN v_record.habit_complete THEN 100 ELSE 0 END +
      CASE WHEN v_record.workout_streak_complete THEN 100 ELSE 0 END +
      CASE WHEN v_record.social_complete THEN 150 ELSE 0 END +
      CASE WHEN v_measurement_logs >= v_record.measurement_target THEN 50 ELSE 0 END
  );
END;
$$;

GRANT EXECUTE ON FUNCTION get_full_weekly_progress(UUID) TO authenticated;

-- VERIFY: select jsonb_path_query(get_full_weekly_progress('<user_id>'::uuid), '$.checkpoints[*] ? (@.name == "weight" || @.name == "measurements")'); -- expect current > 0 for a user with body_measurements rows dated in the current week
