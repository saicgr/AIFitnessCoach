-- ============================================================================
-- Migration 2042: get_user_fitness_profile — richer per-axis scorers
-- ============================================================================
-- DO NOT auto-run. Apply via Supabase MCP `apply_migration` or via the
-- Supabase dashboard SQL editor when you're ready.
--
-- Why this exists:
--   The Discover → tap-profile radar reads from get_user_fitness_profile.
--   Migration 1943 anchored each axis to a simple count-and-clamp metric.
--   For brand-new users (no activity) every axis returns 0.0, which renders
--   as a flat-zero hexagon. This migration upgrades each axis to use a
--   richer signal so even early users see a meaningful shape, and so the
--   axes reflect real fitness performance rather than just engagement.
--
-- Axis formulas (all clamped to [0, 1]; NULL only when source has zero rows):
--   strength    — percent_rank of avg estimated 1RM across compound lifts
--                 (squat, bench, deadlift, OHP) over trailing 60 days.
--                 1RM via Brzycki: weight × (36 / (37 - reps)).
--   muscle      — percent_rank of total volume (sum weight × reps) trailing 30 days.
--   endurance   — percent_rank of weekly cardio_minutes trailing 30 days.
--   recovery    — sleep + rest-day blend, trailing 14 days (no percent_rank
--                 because the sources are sparse for most users).
--   consistency — DISTINCT iso_week count / 8 (cap 1.0) trailing 8 weeks.
--   nutrition   — DISTINCT food_log_date / GREATEST(1, days_since_signup_capped_14).
--
-- Tolerance: every helper wraps its query in a per-axis EXCEPTION block. If
-- a source table doesn't exist or a join fails, the helper returns NULL —
-- never raises. The composite RPC therefore can return some axes filled
-- and others NULL even when underlying schema is partial.
--
-- Privacy gate: existing 1943 contract preserved — when target has
-- profile_stats_visible=FALSE, all target_* axes return NULL and
-- target_stats_hidden returns TRUE. Self-view bypasses the gate.
-- ============================================================================


-- ─── strength: Brzycki 1RM avg across compound lifts (60 days) ──────────────
CREATE OR REPLACE FUNCTION _score_strength(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_score NUMERIC;
BEGIN
  -- Try the Brzycki-based percentile first. If the underlying tables don't
  -- exist on this deploy (or the join fails), fall back to the simpler
  -- personal_records count from migration 1943 so existing prod stays safe.
  BEGIN
    WITH user_lifts AS (
      SELECT
        wl.user_id,
        AVG(
          CASE
            WHEN sl.reps > 0 AND sl.reps < 37 AND sl.weight_kg > 0
            THEN sl.weight_kg * (36.0 / (37.0 - sl.reps))
            ELSE NULL
          END
        ) AS avg_1rm
      FROM workout_logs wl
      JOIN performance_logs sl ON sl.workout_log_id = wl.id
      JOIN exercises ex ON ex.id = sl.exercise_id
      WHERE wl.status = 'completed'
        AND wl.completed_at > NOW() - INTERVAL '60 days'
        AND LOWER(ex.name) ~ '(squat|bench|deadlift|overhead press|ohp)'
      GROUP BY wl.user_id
    ),
    ranked AS (
      SELECT user_id, PERCENT_RANK() OVER (ORDER BY avg_1rm) AS pr
      FROM user_lifts
      WHERE avg_1rm IS NOT NULL
    )
    SELECT pr INTO v_score FROM ranked WHERE user_id = p_user_id;

    IF v_score IS NOT NULL THEN
      RETURN GREATEST(0.0, LEAST(1.0, v_score));
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Schema mismatch (e.g. performance_logs missing weight_kg). Fall through.
    NULL;
  END;

  -- Fallback: 1943 helper logic (PRs in last 30 days, ceiling 6).
  BEGIN
    SELECT LEAST(1.0, COUNT(*)::NUMERIC / 6) INTO v_score
    FROM personal_records
    WHERE user_id = p_user_id
      AND created_at > NOW() - INTERVAL '30 days';

    -- Return NULL only when there's literally no data, never when "small".
    IF v_score IS NULL OR v_score = 0 THEN
      IF NOT EXISTS (SELECT 1 FROM personal_records WHERE user_id = p_user_id) THEN
        RETURN NULL;
      END IF;
    END IF;
    RETURN COALESCE(v_score, 0.0);
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;
$$;


-- ─── muscle: total volume trailing 30 days (percent_rank) ───────────────────
CREATE OR REPLACE FUNCTION _score_muscle(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_score NUMERIC;
BEGIN
  BEGIN
    WITH user_vol AS (
      SELECT
        wl.user_id,
        SUM(COALESCE(sl.weight_kg, 0) * COALESCE(sl.reps, 0)) AS total_volume
      FROM workout_logs wl
      JOIN performance_logs sl ON sl.workout_log_id = wl.id
      WHERE wl.status = 'completed'
        AND wl.completed_at > NOW() - INTERVAL '30 days'
      GROUP BY wl.user_id
      HAVING SUM(COALESCE(sl.weight_kg, 0) * COALESCE(sl.reps, 0)) > 0
    ),
    ranked AS (
      SELECT user_id, PERCENT_RANK() OVER (ORDER BY total_volume) AS pr
      FROM user_vol
    )
    SELECT pr INTO v_score FROM ranked WHERE user_id = p_user_id;

    IF v_score IS NOT NULL THEN
      RETURN GREATEST(0.0, LEAST(1.0, v_score));
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- Fallback: workout-type variety from 1943.
  BEGIN
    SELECT LEAST(1.0, COUNT(DISTINCT LOWER(w.type))::NUMERIC / 5) INTO v_score
    FROM workout_logs wl
    JOIN workouts w ON w.id = wl.workout_id
    WHERE wl.user_id = p_user_id
      AND wl.status = 'completed'
      AND wl.completed_at > NOW() - INTERVAL '14 days'
      AND w.type IS NOT NULL;

    IF v_score IS NULL OR v_score = 0 THEN
      IF NOT EXISTS (
        SELECT 1 FROM workout_logs WHERE user_id = p_user_id AND status = 'completed'
      ) THEN
        RETURN NULL;
      END IF;
    END IF;
    RETURN COALESCE(v_score, 0.0);
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;
$$;


-- ─── endurance: weekly cardio minutes trailing 30 days (percent_rank) ───────
CREATE OR REPLACE FUNCTION _score_endurance(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_score NUMERIC;
  v_total NUMERIC;
BEGIN
  -- Compute this user's trailing 30-day cardio minutes, then percent_rank
  -- against everyone with non-zero cardio in the same window.
  BEGIN
    WITH user_cardio AS (
      SELECT user_id,
             SUM(COALESCE(duration_minutes, 0)) AS cardio_min
      FROM workout_logs wl
      WHERE status = 'completed'
        AND completed_at > NOW() - INTERVAL '30 days'
        AND (
          LOWER(COALESCE(wl.notes, '')) ~ '(cardio|run|cycle|swim|row|hiit)'
          OR EXISTS (
            SELECT 1 FROM workouts w
            WHERE w.id = wl.workout_id
              AND LOWER(COALESCE(w.type, '')) ~ '(cardio|hiit|endurance|run)'
          )
        )
      GROUP BY user_id
      HAVING SUM(COALESCE(duration_minutes, 0)) > 0
    ),
    ranked AS (
      SELECT user_id, PERCENT_RANK() OVER (ORDER BY cardio_min) AS pr
      FROM user_cardio
    )
    SELECT pr INTO v_score FROM ranked WHERE user_id = p_user_id;

    IF v_score IS NOT NULL THEN
      RETURN GREATEST(0.0, LEAST(1.0, v_score));
    END IF;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  -- Fallback: clamp on the user's own minutes (1943-style ceiling).
  BEGIN
    SELECT COALESCE(SUM(duration_minutes), 0) INTO v_total
    FROM workout_logs
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND completed_at > NOW() - INTERVAL '14 days';

    IF v_total = 0 THEN
      IF NOT EXISTS (
        SELECT 1 FROM workout_logs WHERE user_id = p_user_id AND status = 'completed'
      ) THEN
        RETURN NULL;
      END IF;
    END IF;
    RETURN LEAST(1.0, v_total / 500.0);
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;
$$;


-- ─── recovery: avg sleep blend + rest days (14 days) ────────────────────────
-- recovery = LEAST(1.0, (avg_sleep_hr / 8) * 0.6 + (rest_day_count / 2) * 0.4)
-- Sleep is only available when users log it, so a missing sleep table or
-- zero sleep rows falls back to pure rest-day proportion.
CREATE OR REPLACE FUNCTION _score_recovery(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_avg_sleep NUMERIC := NULL;
  v_rest_days NUMERIC := NULL;
  v_workout_days INT;
BEGIN
  -- Average sleep hours, last 14 days. Tolerant: any of these tables may
  -- not exist depending on which features have shipped on this database.
  BEGIN
    SELECT AVG(hours)::NUMERIC INTO v_avg_sleep
    FROM sleep_logs
    WHERE user_id = p_user_id
      AND logged_at > NOW() - INTERVAL '14 days';
  EXCEPTION WHEN OTHERS THEN
    v_avg_sleep := NULL;
  END;

  -- Rest-day count: days in last 14 with NO completed workout. Capped at 14.
  BEGIN
    SELECT COUNT(DISTINCT DATE(completed_at)) INTO v_workout_days
    FROM workout_logs
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND completed_at > NOW() - INTERVAL '14 days';

    v_rest_days := GREATEST(0, 14 - COALESCE(v_workout_days, 0));
  EXCEPTION WHEN OTHERS THEN
    v_rest_days := NULL;
  END;

  -- If we have neither signal, return NULL (no data to score on).
  IF v_avg_sleep IS NULL AND v_rest_days IS NULL THEN
    RETURN NULL;
  END IF;

  -- Blend per spec; if a component is missing, redistribute its weight to
  -- the other component so the score stays in [0, 1].
  IF v_avg_sleep IS NOT NULL AND v_rest_days IS NOT NULL THEN
    RETURN LEAST(
      1.0,
      LEAST(1.0, (v_avg_sleep / 8.0)) * 0.6
      + LEAST(1.0, (v_rest_days / 2.0)) * 0.4
    );
  ELSIF v_avg_sleep IS NOT NULL THEN
    RETURN LEAST(1.0, v_avg_sleep / 8.0);
  ELSE
    RETURN LEAST(1.0, v_rest_days / 4.0);  -- 4 rest days in 14 = 1.0
  END IF;
END;
$$;


-- ─── consistency: DISTINCT iso_week count / 8 over last 8 weeks ─────────────
CREATE OR REPLACE FUNCTION _score_consistency(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_weeks INT;
BEGIN
  BEGIN
    SELECT COUNT(DISTINCT DATE_TRUNC('week', completed_at))::INT INTO v_weeks
    FROM workout_logs
    WHERE user_id = p_user_id
      AND status = 'completed'
      AND completed_at > NOW() - INTERVAL '8 weeks';

    IF v_weeks IS NULL OR v_weeks = 0 THEN
      -- Try login streak fallback (matches 1943 behaviour for engagement-only users).
      RETURN (
        SELECT LEAST(1.0, COALESCE(current_streak, 0)::NUMERIC / 66)
        FROM user_login_streaks WHERE user_id = p_user_id
      );
    END IF;

    RETURN LEAST(1.0, v_weeks::NUMERIC / 8.0);
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;
END;
$$;


-- ─── nutrition: distinct food-log days / days_since_signup (capped 14) ──────
CREATE OR REPLACE FUNCTION _score_nutrition(p_user_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_log_days INT;
  v_days_since_signup INT;
BEGIN
  BEGIN
    SELECT COUNT(DISTINCT DATE(logged_at))::INT INTO v_log_days
    FROM food_logs
    WHERE user_id = p_user_id
      AND deleted_at IS NULL
      AND logged_at > NOW() - INTERVAL '14 days';
  EXCEPTION WHEN OTHERS THEN
    -- Some installs use a different deleted-flag column. Try without it.
    BEGIN
      SELECT COUNT(DISTINCT DATE(logged_at))::INT INTO v_log_days
      FROM food_logs
      WHERE user_id = p_user_id
        AND logged_at > NOW() - INTERVAL '14 days';
    EXCEPTION WHEN OTHERS THEN
      v_log_days := NULL;
    END;
  END;

  IF v_log_days IS NULL THEN
    RETURN NULL;
  END IF;

  IF v_log_days = 0 THEN
    -- Brand-new account with zero food logs. Return NULL rather than 0
    -- so the radar can render "no data" treatment instead of a hard zero.
    RETURN NULL;
  END IF;

  -- Cap denominator at 14 so a 1-day-old user logging their first meal
  -- doesn't suddenly score 1.0; cap floor at 1 to avoid div-by-zero.
  BEGIN
    SELECT LEAST(14, GREATEST(1, EXTRACT(DAY FROM NOW() - created_at)::INT))
    INTO v_days_since_signup
    FROM users WHERE id = p_user_id;
  EXCEPTION WHEN OTHERS THEN
    v_days_since_signup := 14;
  END;

  RETURN LEAST(1.0, v_log_days::NUMERIC / GREATEST(1, COALESCE(v_days_since_signup, 14)));
END;
$$;


-- ─── public composite RPC (signature preserved from 1943) ───────────────────
CREATE OR REPLACE FUNCTION get_user_fitness_profile(
  p_target_user_id UUID,
  p_viewer_user_id UUID DEFAULT NULL
) RETURNS TABLE (
  target_strength NUMERIC, target_muscle NUMERIC, target_recovery NUMERIC,
  target_consistency NUMERIC, target_endurance NUMERIC, target_nutrition NUMERIC,
  viewer_strength NUMERIC, viewer_muscle NUMERIC, viewer_recovery NUMERIC,
  viewer_consistency NUMERIC, viewer_endurance NUMERIC, viewer_nutrition NUMERIC,
  target_bio TEXT, target_stats_hidden BOOLEAN
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_target_hidden BOOLEAN;
BEGIN
  SELECT NOT COALESCE(profile_stats_visible, TRUE) INTO v_target_hidden
  FROM users WHERE id = p_target_user_id;

  -- Self-view bypasses privacy gate
  IF p_viewer_user_id IS NOT NULL AND p_viewer_user_id = p_target_user_id THEN
    v_target_hidden := FALSE;
  END IF;

  RETURN QUERY
  SELECT
    CASE WHEN v_target_hidden THEN NULL ELSE _score_strength(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_muscle(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_recovery(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_consistency(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_endurance(p_target_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE _score_nutrition(p_target_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_strength(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_muscle(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_recovery(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_consistency(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_endurance(p_viewer_user_id) END,
    CASE WHEN p_viewer_user_id IS NULL THEN NULL ELSE _score_nutrition(p_viewer_user_id) END,
    CASE WHEN v_target_hidden THEN NULL ELSE (SELECT bio::TEXT FROM users WHERE id = p_target_user_id) END,
    v_target_hidden;
END;
$$;

GRANT EXECUTE ON FUNCTION _score_strength(UUID)    TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION _score_muscle(UUID)      TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION _score_recovery(UUID)    TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION _score_consistency(UUID) TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION _score_endurance(UUID)   TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION _score_nutrition(UUID)   TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION get_user_fitness_profile(UUID, UUID) TO authenticated, service_role, anon;
