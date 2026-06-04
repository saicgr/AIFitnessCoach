-- Migration 2235: Per-gym-profile progress tracking — attribute logged sets to a gym
--
-- Context: gym_profiles (mig 168) drives workout GENERATION and stamps workouts.gym_profile_id,
-- but the LOGGING chain (workout_logs -> performance_logs -> personal_records / exercise_personal_records)
-- drops the gym entirely, so every progress read, PR, and weight suggestion pools all gyms together.
-- This is the "all numbers become meaningless" bug for machines/cables whose load differs per gym.
--
-- This migration adds gym_profile_id to the four logged-progress tables, backfills it from the
-- parent workout's gym, indexes the per-gym query paths, extends exercise_workout_history in place
-- (additive, no granularity change), and adds *_by_gym sibling views for the metrics whose
-- granularity would otherwise change (muscle volume, all-time PRs) so existing combined consumers
-- are untouched.
--
-- FK is ON DELETE SET NULL: hard-deletes are rare (we soft-archive in mig 2236), and a NULL
-- gym_profile_id = the "Unassigned / combined" bucket.

-- ============================================================================
-- 1. Columns
-- ============================================================================
ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE SET NULL;

ALTER TABLE performance_logs
    ADD COLUMN IF NOT EXISTS gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE SET NULL;

ALTER TABLE personal_records
    ADD COLUMN IF NOT EXISTS gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE SET NULL;

ALTER TABLE exercise_personal_records
    ADD COLUMN IF NOT EXISTS gym_profile_id UUID REFERENCES gym_profiles(id) ON DELETE SET NULL;

-- ============================================================================
-- 2. Indexes for per-gym query paths
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_performance_logs_user_exercise_gym
    ON performance_logs(user_id, exercise_name, gym_profile_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_workout_logs_user_gym
    ON workout_logs(user_id, gym_profile_id);

CREATE INDEX IF NOT EXISTS idx_personal_records_user_exercise_gym
    ON personal_records(user_id, exercise_name, gym_profile_id);

CREATE INDEX IF NOT EXISTS idx_epr_user_exercise_gym
    ON exercise_personal_records(user_id, exercise_name, gym_profile_id);

-- ============================================================================
-- 3. Backfill from the parent workout's gym (provenance = the gym a workout was generated for)
--    Order matters: workout_logs first (join root), then the children inherit from it.
-- ============================================================================
UPDATE workout_logs wl
   SET gym_profile_id = w.gym_profile_id
  FROM workouts w
 WHERE wl.workout_id = w.id
   AND wl.gym_profile_id IS NULL
   AND w.gym_profile_id IS NOT NULL;

UPDATE performance_logs pl
   SET gym_profile_id = wl.gym_profile_id
  FROM workout_logs wl
 WHERE pl.workout_log_id = wl.id
   AND pl.gym_profile_id IS NULL
   AND wl.gym_profile_id IS NOT NULL;

UPDATE personal_records pr
   SET gym_profile_id = w.gym_profile_id
  FROM workouts w
 WHERE pr.workout_id = w.id
   AND pr.gym_profile_id IS NULL
   AND w.gym_profile_id IS NOT NULL;

UPDATE exercise_personal_records epr
   SET gym_profile_id = wl.gym_profile_id
  FROM workout_logs wl
 WHERE epr.workout_log_id = wl.id
   AND epr.gym_profile_id IS NULL
   AND wl.gym_profile_id IS NOT NULL;

-- ============================================================================
-- 4. exercise_workout_history — extend IN PLACE (additive: groups already map
--    1 workout_log -> 1 gym, so adding gym_profile_id to SELECT+GROUP BY does not
--    change the number of rows). gym_profile_id is appended LAST per CREATE OR REPLACE rules.
-- ============================================================================
CREATE OR REPLACE VIEW exercise_workout_history AS
WITH exercise_sets AS (
    SELECT
        wl.user_id,
        wl.id AS workout_log_id,
        wl.workout_id,
        wl.gym_profile_id,
        wl.completed_at,
        lower(set_data.value ->> 'exercise') AS exercise_name,
        (set_data.value ->> 'reps')::integer AS reps,
        ((set_data.value ->> 'weight_lbs')::numeric / 2.20462) AS weight_kg
    FROM workout_logs wl,
    LATERAL jsonb_array_elements(wl.sets_json) set_data(value)
    WHERE wl.completed_at IS NOT NULL
      AND wl.sets_json IS NOT NULL
      AND jsonb_array_length(COALESCE(wl.sets_json, '[]'::jsonb)) > 0
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

-- ============================================================================
-- 5. muscle_group_weekly_volume_by_gym — NEW sibling (the original combined view is
--    left untouched to avoid changing granularity for existing muscle-analytics consumers).
-- ============================================================================
CREATE OR REPLACE VIEW muscle_group_weekly_volume_by_gym AS
WITH exercise_sets AS (
    SELECT
        wl.user_id,
        wl.gym_profile_id,
        date_trunc('week', wl.completed_at)::date AS week_start,
        lower(set_data.value ->> 'exercise') AS exercise_name,
        (set_data.value ->> 'reps')::integer AS reps,
        ((set_data.value ->> 'weight_lbs')::numeric / 2.20462) AS weight_kg,
        wl.id AS workout_log_id
    FROM workout_logs wl,
    LATERAL jsonb_array_elements(wl.sets_json) set_data(value)
    WHERE wl.completed_at IS NOT NULL
      AND wl.sets_json IS NOT NULL
      AND jsonb_array_length(COALESCE(wl.sets_json, '[]'::jsonb)) > 0
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

-- ============================================================================
-- 6. all_time_prs_by_gym — NEW sibling (combined all_time_prs left untouched).
--    Per-gym all-time PR = best estimated_1rm per (user, exercise, gym).
-- ============================================================================
CREATE OR REPLACE VIEW all_time_prs_by_gym AS
SELECT DISTINCT ON (user_id, exercise_name, gym_profile_id)
  id,
  user_id,
  exercise_name,
  muscle_group,
  weight_kg,
  reps,
  estimated_1rm_kg,
  achieved_at,
  gym_profile_id
FROM personal_records
WHERE is_all_time_pr = TRUE
ORDER BY user_id, exercise_name, gym_profile_id, estimated_1rm_kg DESC;

GRANT SELECT ON muscle_group_weekly_volume_by_gym TO authenticated;
GRANT SELECT ON all_time_prs_by_gym TO authenticated;
