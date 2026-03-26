-- Fix calculate_user_roi_metrics:
--   1. workout_logs uses 'completed_at' not 'created_at' (from migration 100)
--   2. workout_logs uses 'total_time_seconds' not 'duration_seconds' (bug in migration 1649)
-- Also: Add error handling to milestone trigger so failures don't roll back workout log INSERTs

-- Part 1: Fix the ROI metrics function
CREATE OR REPLACE FUNCTION calculate_user_roi_metrics(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_first_workout TIMESTAMPTZ;
    v_last_workout TIMESTAMPTZ;
    v_total_workouts INTEGER;
    v_total_time INTEGER;
    v_total_weight FLOAT;
    v_total_prs INTEGER;
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_week_workouts INTEGER;
    v_month_workouts INTEGER;
BEGIN
    -- Get workout stats
    SELECT
        MIN(completed_at),
        MAX(completed_at),
        COUNT(*),
        COALESCE(SUM(total_time_seconds), 0)
    INTO v_first_workout, v_last_workout, v_total_workouts, v_total_time
    FROM workout_logs
    WHERE user_id = p_user_id
    AND status = 'completed';

    -- Get total weight lifted (from exercise_logs)
    SELECT COALESCE(SUM(
        CASE
            WHEN weight_unit = 'kg' THEN weight_used * 2.20462 * reps_completed * sets_completed
            ELSE weight_used * reps_completed * sets_completed
        END
    ), 0)
    INTO v_total_weight
    FROM exercise_logs el
    JOIN workout_logs wl ON el.workout_log_id = wl.id
    WHERE wl.user_id = p_user_id
    AND wl.status = 'completed';

    -- Get PR count
    SELECT COUNT(*) INTO v_total_prs
    FROM personal_records
    WHERE user_id = p_user_id;

    -- Get streak info from user_streaks table
    SELECT COALESCE(current_streak, 0), COALESCE(longest_streak, 0)
    INTO v_current_streak, v_longest_streak
    FROM user_streaks
    WHERE user_id = p_user_id AND streak_type = 'workout';

    -- Get this week's workouts
    SELECT COUNT(*) INTO v_week_workouts
    FROM workout_logs
    WHERE user_id = p_user_id
    AND status = 'completed'
    AND completed_at >= date_trunc('week', NOW());

    -- Get this month's workouts
    SELECT COUNT(*) INTO v_month_workouts
    FROM workout_logs
    WHERE user_id = p_user_id
    AND status = 'completed'
    AND completed_at >= date_trunc('month', NOW());

    -- Upsert ROI metrics
    INSERT INTO user_roi_metrics (
        user_id,
        total_workouts_completed,
        total_workout_time_seconds,
        total_weight_lifted_lbs,
        total_weight_lifted_kg,
        estimated_calories_burned,
        prs_achieved_count,
        current_streak_days,
        longest_streak_days,
        first_workout_date,
        last_workout_date,
        journey_days,
        workouts_this_week,
        workouts_this_month,
        average_workouts_per_week,
        last_calculated_at
    ) VALUES (
        p_user_id,
        v_total_workouts,
        v_total_time,
        v_total_weight,
        v_total_weight / 2.20462,
        (v_total_time / 60) * 7, -- ~7 calories per minute estimate
        v_total_prs,
        v_current_streak,
        v_longest_streak,
        v_first_workout,
        v_last_workout,
        EXTRACT(DAY FROM (NOW() - v_first_workout))::INTEGER,
        v_week_workouts,
        v_month_workouts,
        CASE
            WHEN v_first_workout IS NOT NULL
            THEN v_total_workouts::FLOAT / GREATEST(1, EXTRACT(WEEK FROM (NOW() - v_first_workout)))
            ELSE 0
        END,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        total_workouts_completed = EXCLUDED.total_workouts_completed,
        total_workout_time_seconds = EXCLUDED.total_workout_time_seconds,
        total_weight_lifted_lbs = EXCLUDED.total_weight_lifted_lbs,
        total_weight_lifted_kg = EXCLUDED.total_weight_lifted_kg,
        estimated_calories_burned = EXCLUDED.estimated_calories_burned,
        prs_achieved_count = EXCLUDED.prs_achieved_count,
        current_streak_days = EXCLUDED.current_streak_days,
        longest_streak_days = EXCLUDED.longest_streak_days,
        first_workout_date = EXCLUDED.first_workout_date,
        last_workout_date = EXCLUDED.last_workout_date,
        journey_days = EXCLUDED.journey_days,
        workouts_this_week = EXCLUDED.workouts_this_week,
        workouts_this_month = EXCLUDED.workouts_this_month,
        average_workouts_per_week = EXCLUDED.average_workouts_per_week,
        last_calculated_at = NOW(),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Part 2: Add error handling to milestone trigger
-- Milestone calculation is a side effect - it must NEVER block workout log inserts
CREATE OR REPLACE FUNCTION trigger_check_milestones_on_workout()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        BEGIN
            PERFORM check_and_award_milestones(NEW.user_id);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Milestone check failed for user %: %', NEW.user_id, SQLERRM;
        END;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
