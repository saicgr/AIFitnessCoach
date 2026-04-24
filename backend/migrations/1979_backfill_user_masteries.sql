-- Migration 1979: Backfill user_masteries from pre-existing history.
--
-- Before this migration, user_masteries was write-only in the schema —
-- no code path actually populated it, so every user saw Lv.0 on the
-- MASTERIES grid even after logging dozens of workouts.
-- services/mastery_writes.py now keeps it fresh going forward (hooked
-- into apple_health_push + workouts/complete); this migration backfills
-- existing rows one time.
--
-- Source tables match services/mastery_writes.py exactly:
--   • workouts (is_completed = TRUE)                — all completed sessions
--   • cardio_logs                                   — file/OAuth cardio
--   • workout_history_imports                        — strength imports
--                                                     (one session per day)
--   • generation_metadata (jsonb, sometimes stringified) on `workouts`
--                                                     for calories/distance

BEGIN;

-- Keep these in sync with services/mastery_writes.py.
CREATE TEMP TABLE _running_activity_kinds (kind TEXT) ON COMMIT DROP;
INSERT INTO _running_activity_kinds (kind) VALUES ('run'), ('trail_run'), ('treadmill');

CREATE TEMP TABLE _running_workout_types (typ TEXT) ON COMMIT DROP;
INSERT INTO _running_workout_types (typ) VALUES ('running'), ('run'), ('jog'), ('jogging');

-- Helper: coerce generation_metadata to jsonb *object*. Production has
-- some rows where the column holds a stringified JSON (jsonb of a
-- string rather than of an object). Double-parse for that shape.
CREATE OR REPLACE FUNCTION pg_temp.meta_as_object(raw JSONB) RETURNS JSONB AS $$
DECLARE
  out JSONB;
BEGIN
  IF raw IS NULL THEN
    RETURN NULL;
  ELSIF jsonb_typeof(raw) = 'object' THEN
    RETURN raw;
  ELSIF jsonb_typeof(raw) = 'string' THEN
    BEGIN
      out := (raw #>> '{}')::jsonb;
      IF jsonb_typeof(out) = 'object' THEN
        RETURN out;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RETURN NULL;
    END;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Per-user aggregate rollup.
CREATE TEMP TABLE _user_aggregates ON COMMIT DROP AS
WITH users_with_history AS (
    SELECT DISTINCT user_id FROM cardio_logs
    UNION
    SELECT DISTINCT user_id FROM workout_history_imports
    UNION
    SELECT DISTINCT user_id FROM workouts WHERE is_completed = TRUE
),
workout_rollups AS (
    SELECT
        user_id,
        COUNT(*)                                                 AS w_sessions,
        COALESCE(SUM(duration_minutes), 0)::BIGINT               AS w_active_min,
        COALESCE(SUM(
            COALESCE(
                (pg_temp.meta_as_object(generation_metadata)->>'calories_burned')::NUMERIC,
                (pg_temp.meta_as_object(generation_metadata)->>'calories_active')::NUMERIC,
                (pg_temp.meta_as_object(generation_metadata)->>'calories_total')::NUMERIC,
                (pg_temp.meta_as_object(generation_metadata)->>'calories')::NUMERIC,
                0
            )
        ), 0)::BIGINT                                            AS w_calories,
        COALESCE(SUM(
            CASE WHEN LOWER(type) IN (SELECT typ FROM _running_workout_types)
                 THEN COALESCE(
                       (pg_temp.meta_as_object(generation_metadata)->>'distance_m')::NUMERIC,
                       (pg_temp.meta_as_object(generation_metadata)->>'distance_meters')::NUMERIC,
                       0) / 1000.0
                 ELSE 0 END
        ), 0)::BIGINT                                            AS w_running_km,
        COALESCE(SUM(
            COALESCE(
                (pg_temp.meta_as_object(generation_metadata)->>'elevation_gain_m')::NUMERIC,
                0)
        ), 0)::BIGINT                                            AS w_elev_m
    FROM workouts
    WHERE is_completed = TRUE
    GROUP BY user_id
),
cardio_rollups AS (
    SELECT
        user_id,
        COUNT(*)                                                 AS c_sessions,
        COALESCE(SUM(duration_seconds) / 60, 0)::BIGINT          AS c_active_min,
        COALESCE(SUM(calories), 0)::BIGINT                       AS c_calories,
        COALESCE(SUM(
            CASE WHEN activity_type IN (SELECT kind FROM _running_activity_kinds)
                 THEN distance_m / 1000.0
                 ELSE 0 END
        ), 0)::BIGINT                                            AS c_running_km,
        COALESCE(SUM(elevation_gain_m), 0)::BIGINT               AS c_elev_m
    FROM cardio_logs
    GROUP BY user_id
),
import_rollups AS (
    SELECT user_id, COUNT(DISTINCT DATE(performed_at))::BIGINT   AS i_sessions
    FROM workout_history_imports
    GROUP BY user_id
)
SELECT
    u.user_id,
    0::BIGINT                                                    AS steps,
    COALESCE(wr.w_calories, 0)   + COALESCE(cr.c_calories, 0)    AS calories,
    COALESCE(wr.w_running_km, 0) + COALESCE(cr.c_running_km, 0)  AS running,
    COALESCE(wr.w_active_min, 0) + COALESCE(cr.c_active_min, 0)  AS active_minutes,
    COALESCE(wr.w_sessions, 0)
      + COALESCE(cr.c_sessions, 0)
      + COALESCE(ir.i_sessions, 0)                               AS sessions,
    COALESCE(wr.w_elev_m, 0)     + COALESCE(cr.c_elev_m, 0)      AS elevation
FROM users_with_history u
LEFT JOIN workout_rollups wr ON wr.user_id = u.user_id
LEFT JOIN cardio_rollups  cr ON cr.user_id = u.user_id
LEFT JOIN import_rollups  ir ON ir.user_id = u.user_id;

-- Upsert one row per (user, mastery_key). Level = count of thresholds
-- crossed. The runtime path handles the past-last-threshold doubling;
-- for the backfill, capping at the seeded max level is acceptable.
INSERT INTO user_masteries (user_id, mastery_key, current_value, current_level, updated_at)
SELECT
    agg.user_id,
    md.key,
    CASE md.key
        WHEN 'steps'          THEN agg.steps
        WHEN 'calories'       THEN agg.calories
        WHEN 'running'        THEN agg.running
        WHEN 'active_minutes' THEN agg.active_minutes
        WHEN 'sessions'       THEN agg.sessions
        WHEN 'elevation'      THEN agg.elevation
    END AS current_value,
    (
        SELECT COUNT(*)
        FROM jsonb_array_elements_text(md.level_thresholds) AS t(v)
        WHERE (CASE md.key
                  WHEN 'steps'          THEN agg.steps
                  WHEN 'calories'       THEN agg.calories
                  WHEN 'running'        THEN agg.running
                  WHEN 'active_minutes' THEN agg.active_minutes
                  WHEN 'sessions'       THEN agg.sessions
                  WHEN 'elevation'      THEN agg.elevation
               END) >= (t.v::BIGINT)
    )::INT AS current_level,
    NOW()
FROM _user_aggregates agg
CROSS JOIN mastery_definitions md
ON CONFLICT (user_id, mastery_key) DO UPDATE
    SET current_value = EXCLUDED.current_value,
        current_level = EXCLUDED.current_level,
        updated_at    = NOW();

COMMIT;
