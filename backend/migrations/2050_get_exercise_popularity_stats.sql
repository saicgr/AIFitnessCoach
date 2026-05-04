-- 2050_get_exercise_popularity_stats.sql
--
-- Population-level exercise popularity signal for collaborative-filtering
-- exercise selection on the home screen. backend/api/v1/exercise_popularity.py
-- was calling this RPC and silently falling back to an empty cache because
-- the function never existed.
--
-- Returns: muscle_group (URL slug), goal, exercise_name, score (0..1)
--
-- Score = popularity * 0.4 + low_rpe * 0.3 + pr_rate * 0.3
--   popularity = unique users on this exercise / max unique users in muscle
--   low_rpe    = comfort signal, (10 - clamped avg_rpe) / 10
--   pr_rate    = fraction of completed weighted sets that hit the user's exercise max
--
-- Filters:
--   exclude_user_id      — drop this user's logs (anti self-reinforcing loop)
--   fitness_level_filter — only count logs from users at this fitness level
--
-- muscle_group is normalized to URL-friendly slugs ("back", "quads", "abs")
-- so the endpoint can match the path param directly against the result key.
-- exercise_muscle_mappings (is_primary=TRUE) is the source of truth — it has
-- a clean taxonomy, unlike exercise_library.target_muscle which carries
-- verbose anatomical strings.

CREATE OR REPLACE FUNCTION public.get_exercise_popularity_stats(
    exclude_user_id        uuid DEFAULT NULL,
    fitness_level_filter   text DEFAULT NULL
)
RETURNS TABLE (
    muscle_group   text,
    goal           text,
    exercise_name  text,
    score          numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    WITH filtered_logs AS (
        SELECT
            pl.user_id,
            lower(trim(pl.exercise_name)) AS ex_name,
            pl.weight_kg,
            pl.rpe
        FROM performance_logs pl
        LEFT JOIN users u ON u.id = pl.user_id
        WHERE pl.is_completed = TRUE
          AND pl.exercise_name IS NOT NULL
          AND (exclude_user_id IS NULL OR pl.user_id <> exclude_user_id)
          AND (fitness_level_filter IS NULL OR u.fitness_level = fitness_level_filter)
    ),
    user_exercise_max AS (
        SELECT user_id, ex_name, MAX(weight_kg) AS user_max_weight
        FROM filtered_logs
        WHERE weight_kg IS NOT NULL
        GROUP BY user_id, ex_name
    ),
    exercise_stats AS (
        SELECT
            fl.ex_name,
            COUNT(DISTINCT fl.user_id)                                 AS distinct_users,
            AVG(fl.rpe) FILTER (WHERE fl.rpe IS NOT NULL)              AS avg_rpe,
            COALESCE(
                SUM(CASE WHEN fl.weight_kg IS NOT NULL
                          AND uem.user_max_weight IS NOT NULL
                          AND fl.weight_kg >= uem.user_max_weight
                         THEN 1 ELSE 0 END)::numeric
                  / NULLIF(SUM(CASE WHEN fl.weight_kg IS NOT NULL THEN 1 ELSE 0 END), 0),
                0
            ) AS pr_rate
        FROM filtered_logs fl
        LEFT JOIN user_exercise_max uem
               ON uem.user_id = fl.user_id AND uem.ex_name = fl.ex_name
        GROUP BY fl.ex_name
    ),
    -- Map exercise_muscle_mappings.muscle_group → URL slug used by the endpoint.
    -- One exercise can hit multiple primary muscles → one row each.
    exercise_muscle_resolved AS (
        SELECT
            lower(trim(emm.exercise_name)) AS ex_name,
            CASE lower(emm.muscle_group)
                WHEN 'chest'             THEN 'chest'
                WHEN 'shoulders'         THEN 'shoulders'
                WHEN 'glutes'            THEN 'glutes'
                WHEN 'hamstrings'        THEN 'hamstrings'
                WHEN 'quadriceps'        THEN 'quads'
                WHEN 'latissimus dorsi'  THEN 'back'
                WHEN 'upper back'        THEN 'back'
                WHEN 'biceps'            THEN 'biceps'
                WHEN 'triceps'           THEN 'triceps'
                WHEN 'calves'            THEN 'calves'
                WHEN 'abs'               THEN 'abs'
                WHEN 'core'              THEN 'abs'
                WHEN 'forearms'          THEN 'forearms'
                WHEN 'full body'         THEN 'full_body'
                ELSE lower(emm.muscle_group)
            END AS muscle_slug
        FROM exercise_muscle_mappings emm
        WHERE emm.is_primary = TRUE
          AND emm.muscle_group IS NOT NULL
    ),
    enriched AS (
        SELECT
            emr.muscle_slug                                              AS muscle_group,
            COALESCE(NULLIF(lower(g.goal), ''), 'hypertrophy')           AS goal,
            es.ex_name                                                   AS exercise_name,
            es.distinct_users,
            es.avg_rpe,
            es.pr_rate
        FROM exercise_stats es
        JOIN exercise_muscle_resolved emr ON emr.ex_name = es.ex_name
        LEFT JOIN exercise_library el
              ON lower(trim(el.exercise_name)) = es.ex_name
        LEFT JOIN LATERAL (
            SELECT goal_text AS goal
              FROM unnest(COALESCE(NULLIF(el.goals, ARRAY[]::text[]), ARRAY['hypertrophy']::text[])) AS goal_text
        ) g ON TRUE
    ),
    muscle_max AS (
        SELECT muscle_group, MAX(distinct_users) AS max_users
        FROM enriched
        GROUP BY muscle_group
    )
    SELECT
        e.muscle_group,
        e.goal,
        e.exercise_name,
        ROUND(
            (
                LEAST(1.0, e.distinct_users::numeric / NULLIF(mm.max_users, 0)) * 0.4
                + COALESCE((10.0 - LEAST(10.0, GREATEST(1.0, e.avg_rpe))) / 10.0, 0.5) * 0.3
                + LEAST(1.0, e.pr_rate) * 0.3
            )::numeric,
            4
        ) AS score
    FROM enriched e
    JOIN muscle_max mm USING (muscle_group)
    WHERE e.muscle_group <> ''
$$;

COMMENT ON FUNCTION public.get_exercise_popularity_stats(uuid, text) IS
    'Aggregates performance_logs into per-(muscle, goal, exercise) popularity scores '
    '(0..1) for collaborative-filtering exercise selection. muscle_group is a URL slug '
    '(chest/back/quads/etc) joined via exercise_muscle_mappings. exclude_user_id avoids '
    'self-reinforcing loops.';

GRANT EXECUTE ON FUNCTION public.get_exercise_popularity_stats(uuid, text)
    TO anon, authenticated, service_role;
