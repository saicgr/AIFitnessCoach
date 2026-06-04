-- Migration 2238: make the sets_json-parsing views format-robust
--
-- Root cause: workout_logs.sets_json has drifted across formats over time, but the
-- views only ever parsed the OLDEST one:
--   * Format 1 (<= 2026-03-30): {"exercise": ..., "weight_lbs": ..., "reps": ...}   <- views read THIS
--   * Format 2 (current app, since ~Apr): {"exercise_name": ..., "weight_kg": ..., "reps": ...}
--   * Format 3 (legacy summary): {"name": ..., "weight_kg": ..., "sets": N, "reps": ...}
-- exercise_workout_history + muscle_group_weekly_volume (+ the _by_gym mirror) read only
-- 'exercise' / 'weight_lbs', so they have been BLIND to ~2 months of logs (everything the
-- current app writes), breaking per-exercise history, progress charts, muscle analytics, AND
-- the new per-gym filters that ride on these views.
--
-- Fix: parse the exercise name from exercise|exercise_name|name, take weight from weight_kg
-- (already kg) else weight_lbs/2.20462, and skip is_completed=false placeholder rows. Column
-- lists/types are unchanged so CREATE OR REPLACE is safe and gym_profile_id additions (mig 2235)
-- are preserved.

-- ---------- exercise_workout_history (carries gym_profile_id from mig 2235) ----------
CREATE OR REPLACE VIEW exercise_workout_history AS
WITH exercise_sets AS (
    SELECT
        wl.user_id,
        wl.id AS workout_log_id,
        wl.workout_id,
        wl.gym_profile_id,
        wl.completed_at,
        lower(COALESCE(set_data.value ->> 'exercise',
                       set_data.value ->> 'exercise_name',
                       set_data.value ->> 'name')) AS exercise_name,
        NULLIF(set_data.value ->> 'reps', '')::numeric::integer AS reps,
        COALESCE(
            NULLIF(set_data.value ->> 'weight_kg', '')::numeric,
            NULLIF(set_data.value ->> 'weight_lbs', '')::numeric / 2.20462
        ) AS weight_kg
    FROM workout_logs wl,
    LATERAL jsonb_array_elements(wl.sets_json) set_data(value)
    WHERE wl.completed_at IS NOT NULL
      AND wl.sets_json IS NOT NULL
      AND jsonb_array_length(COALESCE(wl.sets_json, '[]'::jsonb)) > 0
      AND COALESCE(set_data.value ->> 'is_completed', 'true') <> 'false'
)
SELECT
    es.user_id,
    es.exercise_name,
    COALESCE(
        (SELECT lower(el.display_body_part)
         FROM exercise_library_cleaned el
         WHERE lower(el.name) = es.exercise_name
         LIMIT 1),
        CASE
            WHEN es.exercise_name LIKE '%bench press%'
              OR es.exercise_name LIKE '%chest fly%'
              OR es.exercise_name LIKE '%cable fl%'
              OR es.exercise_name LIKE '%pec deck%'
              OR es.exercise_name LIKE '%incline%press%'
              OR es.exercise_name LIKE '%decline%press%'   THEN 'chest'
            WHEN es.exercise_name LIKE '%squat%'
              OR es.exercise_name LIKE '%leg press%'
              OR es.exercise_name LIKE '%lunge%'
              OR es.exercise_name LIKE '%leg extension%'
              OR es.exercise_name LIKE '%step up%'         THEN 'quadriceps'
            WHEN es.exercise_name LIKE '%deadlift%'
              OR es.exercise_name LIKE '%hamstring%'
              OR es.exercise_name LIKE '%leg curl%'        THEN 'hamstrings'
            WHEN es.exercise_name LIKE '%pull up%'
              OR es.exercise_name LIKE '%pull-up%'
              OR es.exercise_name LIKE '%chin up%'
              OR es.exercise_name LIKE '%chin-up%'
              OR es.exercise_name LIKE '%lat pull%'
              OR es.exercise_name LIKE '%seated row%'
              OR es.exercise_name LIKE '%cable row%'
              OR es.exercise_name LIKE '%t-bar row%'
              OR es.exercise_name LIKE '%barbell row%'
              OR es.exercise_name LIKE '%dumbbell row%'    THEN 'back'
            WHEN es.exercise_name LIKE '%curl%'            THEN 'biceps'
            WHEN es.exercise_name LIKE '%tricep%'
              OR es.exercise_name LIKE '%pushdown%'
              OR es.exercise_name LIKE '%skull%'
              OR es.exercise_name LIKE '%close grip%'      THEN 'triceps'
            WHEN es.exercise_name LIKE '%shoulder%'
              OR es.exercise_name LIKE '%lateral raise%'
              OR es.exercise_name LIKE '%overhead press%'
              OR es.exercise_name LIKE '%military press%'
              OR es.exercise_name LIKE '%face pull%'
              OR es.exercise_name LIKE '%rear delt%'
              OR es.exercise_name LIKE '%upright row%'     THEN 'shoulders'
            WHEN es.exercise_name LIKE '%calf%'
              OR es.exercise_name LIKE '%gastrocnemius%'   THEN 'calves'
            WHEN es.exercise_name LIKE '%glute%'
              OR es.exercise_name LIKE '%hip thrust%'
              OR es.exercise_name LIKE '%hip extension%'   THEN 'glutes'
            WHEN es.exercise_name LIKE '%ab %'
              OR es.exercise_name LIKE '%crunch%'
              OR es.exercise_name LIKE '%plank%'
              OR es.exercise_name LIKE '%core%'
              OR es.exercise_name LIKE '%sit up%'
              OR es.exercise_name LIKE '%sit-up%'          THEN 'core'
            WHEN es.exercise_name LIKE '%incline%'         THEN 'chest'
            ELSE 'other'
        END
    ) AS muscle_group,
    es.workout_log_id,
    es.workout_id,
    date(es.completed_at) AS workout_date,
    es.completed_at,
    count(*)::integer AS sets_completed,
    sum(COALESCE(es.reps, 0))::integer AS total_reps,
    sum(COALESCE(es.weight_kg * es.reps::numeric, 0::numeric))::numeric(10,2) AS total_volume_kg,
    max(COALESCE(es.weight_kg, 0::numeric))::numeric(10,2) AS max_weight_kg,
    max(
        CASE
            WHEN es.weight_kg > 0 AND es.reps >= 1 AND es.reps <= 12
            THEN es.weight_kg * (1::numeric + es.reps::numeric / 30::numeric)
            ELSE NULL
        END
    )::numeric(10,2) AS estimated_1rm_kg,
    NULL::numeric(3,1) AS avg_rpe,
    es.gym_profile_id AS gym_profile_id
FROM exercise_sets es
WHERE es.exercise_name IS NOT NULL
GROUP BY es.user_id, es.workout_log_id, es.workout_id, es.completed_at, es.exercise_name, es.gym_profile_id
ORDER BY es.user_id, es.exercise_name, es.completed_at DESC;

-- ---------- muscle_group_weekly_volume (combined, base view) ----------
CREATE OR REPLACE VIEW muscle_group_weekly_volume AS
WITH exercise_sets AS (
    SELECT
        wl.user_id,
        date_trunc('week', wl.completed_at)::date AS week_start,
        lower(COALESCE(set_data.value ->> 'exercise',
                       set_data.value ->> 'exercise_name',
                       set_data.value ->> 'name')) AS exercise_name,
        NULLIF(set_data.value ->> 'reps', '')::numeric::integer AS reps,
        COALESCE(
            NULLIF(set_data.value ->> 'weight_kg', '')::numeric,
            NULLIF(set_data.value ->> 'weight_lbs', '')::numeric / 2.20462
        ) AS weight_kg,
        wl.id AS workout_log_id
    FROM workout_logs wl,
    LATERAL jsonb_array_elements(wl.sets_json) set_data(value)
    WHERE wl.completed_at IS NOT NULL
      AND wl.sets_json IS NOT NULL
      AND jsonb_array_length(COALESCE(wl.sets_json, '[]'::jsonb)) > 0
      AND COALESCE(set_data.value ->> 'is_completed', 'true') <> 'false'
),
sets_with_muscle AS (
    SELECT
        es.user_id,
        es.week_start,
        es.workout_log_id,
        es.reps,
        es.weight_kg,
        COALESCE(
            (SELECT lower(el.display_body_part)
             FROM exercise_library_cleaned el
             WHERE lower(el.name) = es.exercise_name
             LIMIT 1),
            CASE
                WHEN es.exercise_name LIKE '%bench press%'
                  OR es.exercise_name LIKE '%chest fly%'
                  OR es.exercise_name LIKE '%cable fl%'
                  OR es.exercise_name LIKE '%pec deck%'
                  OR es.exercise_name LIKE '%incline%press%'
                  OR es.exercise_name LIKE '%decline%press%' THEN 'chest'
                WHEN es.exercise_name LIKE '%squat%'
                  OR es.exercise_name LIKE '%leg press%'
                  OR es.exercise_name LIKE '%lunge%'
                  OR es.exercise_name LIKE '%leg extension%' THEN 'quadriceps'
                WHEN es.exercise_name LIKE '%deadlift%'
                  OR es.exercise_name LIKE '%hamstring%'
                  OR es.exercise_name LIKE '%leg curl%'      THEN 'hamstrings'
                WHEN es.exercise_name LIKE '%pull up%'
                  OR es.exercise_name LIKE '%pull-up%'
                  OR es.exercise_name LIKE '%chin up%'
                  OR es.exercise_name LIKE '%chin-up%'
                  OR es.exercise_name LIKE '%lat pull%'
                  OR es.exercise_name LIKE '%barbell row%'
                  OR es.exercise_name LIKE '%dumbbell row%'
                  OR es.exercise_name LIKE '%seated row%'
                  OR es.exercise_name LIKE '%cable row%'     THEN 'back'
                WHEN es.exercise_name LIKE '%curl%'          THEN 'biceps'
                WHEN es.exercise_name LIKE '%tricep%'
                  OR es.exercise_name LIKE '%pushdown%'
                  OR es.exercise_name LIKE '%skull%'         THEN 'triceps'
                WHEN es.exercise_name LIKE '%shoulder%'
                  OR es.exercise_name LIKE '%lateral raise%'
                  OR es.exercise_name LIKE '%overhead press%'
                  OR es.exercise_name LIKE '%face pull%'
                  OR es.exercise_name LIKE '%rear delt%'     THEN 'shoulders'
                WHEN es.exercise_name LIKE '%calf%'          THEN 'calves'
                WHEN es.exercise_name LIKE '%glute%'
                  OR es.exercise_name LIKE '%hip thrust%'    THEN 'glutes'
                WHEN es.exercise_name LIKE '%crunch%'
                  OR es.exercise_name LIKE '%plank%'
                  OR es.exercise_name LIKE '%core%'          THEN 'core'
                WHEN es.exercise_name LIKE '%incline%'       THEN 'chest'
                ELSE 'other'
            END
        ) AS muscle_group
    FROM exercise_sets es
    WHERE es.exercise_name IS NOT NULL
)
SELECT
    user_id,
    week_start,
    muscle_group,
    count(DISTINCT workout_log_id)::integer AS workout_count,
    count(*)::integer AS total_sets,
    sum(COALESCE(reps, 0))::integer AS total_reps,
    sum(COALESCE(weight_kg * reps::numeric, 0::numeric))::numeric(10,2) AS total_volume_kg,
    max(COALESCE(weight_kg, 0::numeric))::numeric(10,2) AS max_weight_kg
FROM sets_with_muscle
GROUP BY user_id, week_start, muscle_group
ORDER BY week_start DESC, muscle_group;

-- ---------- muscle_group_weekly_volume_by_gym (per-gym mirror, mig 2235) ----------
CREATE OR REPLACE VIEW muscle_group_weekly_volume_by_gym AS
WITH exercise_sets AS (
    SELECT
        wl.user_id,
        wl.gym_profile_id,
        date_trunc('week', wl.completed_at)::date AS week_start,
        lower(COALESCE(set_data.value ->> 'exercise',
                       set_data.value ->> 'exercise_name',
                       set_data.value ->> 'name')) AS exercise_name,
        NULLIF(set_data.value ->> 'reps', '')::numeric::integer AS reps,
        COALESCE(
            NULLIF(set_data.value ->> 'weight_kg', '')::numeric,
            NULLIF(set_data.value ->> 'weight_lbs', '')::numeric / 2.20462
        ) AS weight_kg,
        wl.id AS workout_log_id
    FROM workout_logs wl,
    LATERAL jsonb_array_elements(wl.sets_json) set_data(value)
    WHERE wl.completed_at IS NOT NULL
      AND wl.sets_json IS NOT NULL
      AND jsonb_array_length(COALESCE(wl.sets_json, '[]'::jsonb)) > 0
      AND COALESCE(set_data.value ->> 'is_completed', 'true') <> 'false'
),
sets_with_muscle AS (
    SELECT
        es.user_id,
        es.gym_profile_id,
        es.week_start,
        es.workout_log_id,
        es.reps,
        es.weight_kg,
        COALESCE(
            (SELECT lower(el.display_body_part)
             FROM exercise_library_cleaned el
             WHERE lower(el.name) = es.exercise_name
             LIMIT 1),
            CASE
                WHEN es.exercise_name LIKE '%bench press%'
                  OR es.exercise_name LIKE '%chest fly%'
                  OR es.exercise_name LIKE '%cable fl%'
                  OR es.exercise_name LIKE '%pec deck%'
                  OR es.exercise_name LIKE '%incline%press%'
                  OR es.exercise_name LIKE '%decline%press%' THEN 'chest'
                WHEN es.exercise_name LIKE '%squat%'
                  OR es.exercise_name LIKE '%leg press%'
                  OR es.exercise_name LIKE '%lunge%'
                  OR es.exercise_name LIKE '%leg extension%' THEN 'quadriceps'
                WHEN es.exercise_name LIKE '%deadlift%'
                  OR es.exercise_name LIKE '%hamstring%'
                  OR es.exercise_name LIKE '%leg curl%'      THEN 'hamstrings'
                WHEN es.exercise_name LIKE '%pull up%'
                  OR es.exercise_name LIKE '%pull-up%'
                  OR es.exercise_name LIKE '%chin up%'
                  OR es.exercise_name LIKE '%chin-up%'
                  OR es.exercise_name LIKE '%lat pull%'
                  OR es.exercise_name LIKE '%barbell row%'
                  OR es.exercise_name LIKE '%dumbbell row%'
                  OR es.exercise_name LIKE '%seated row%'
                  OR es.exercise_name LIKE '%cable row%'     THEN 'back'
                WHEN es.exercise_name LIKE '%curl%'          THEN 'biceps'
                WHEN es.exercise_name LIKE '%tricep%'
                  OR es.exercise_name LIKE '%pushdown%'
                  OR es.exercise_name LIKE '%skull%'         THEN 'triceps'
                WHEN es.exercise_name LIKE '%shoulder%'
                  OR es.exercise_name LIKE '%lateral raise%'
                  OR es.exercise_name LIKE '%overhead press%'
                  OR es.exercise_name LIKE '%face pull%'
                  OR es.exercise_name LIKE '%rear delt%'     THEN 'shoulders'
                WHEN es.exercise_name LIKE '%calf%'          THEN 'calves'
                WHEN es.exercise_name LIKE '%glute%'
                  OR es.exercise_name LIKE '%hip thrust%'    THEN 'glutes'
                WHEN es.exercise_name LIKE '%crunch%'
                  OR es.exercise_name LIKE '%plank%'
                  OR es.exercise_name LIKE '%core%'          THEN 'core'
                WHEN es.exercise_name LIKE '%incline%'       THEN 'chest'
                ELSE 'other'
            END
        ) AS muscle_group
    FROM exercise_sets es
    WHERE es.exercise_name IS NOT NULL
)
SELECT
    user_id,
    gym_profile_id,
    week_start,
    muscle_group,
    count(DISTINCT workout_log_id)::integer AS workout_count,
    count(*)::integer AS total_sets,
    sum(COALESCE(reps, 0))::integer AS total_reps,
    sum(COALESCE(weight_kg * reps::numeric, 0::numeric))::numeric(10,2) AS total_volume_kg,
    max(COALESCE(weight_kg, 0::numeric))::numeric(10,2) AS max_weight_kg
FROM sets_with_muscle
GROUP BY user_id, gym_profile_id, week_start, muscle_group
ORDER BY week_start DESC, muscle_group;
