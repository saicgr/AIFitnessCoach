-- Migration 2252: fitness_index_cohort_snapshot + percentile RPC (k-anonymous).
--
-- Samsung's Fitness Index benchmarks each axis "against your peers". We replicate that
-- with a periodically-refreshed snapshot of every user's LATEST per-axis values, and a
-- percentile RPC that ranks one user against the cohort.
--
-- Privacy: this is the first cross-user aggregate that exposes a derived rank, so it is
-- k-anonymous — compute_fitness_index_percentile returns NULL percentiles when the
-- cohort with data for an axis is smaller than MIN_COHORT (30). It also honours the
-- existing profile_stats_visible flag (users opted out are excluded from the cohort).
--
-- refresh_fitness_index_cohort_snapshot() is called by a cron (see render.yaml) and
-- repopulates the snapshot from the latest fitness_index_daily row per user.
--
-- Idempotent: CREATE ... IF NOT EXISTS, CREATE OR REPLACE FUNCTION.

CREATE TABLE IF NOT EXISTS fitness_index_cohort_snapshot (
    user_id       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    body_comp     SMALLINT,
    cardio        SMALLINT,
    strength      SMALLINT,
    endurance     SMALLINT,
    flexibility   SMALLINT,
    overall       SMALLINT,
    snapshot_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE fitness_index_cohort_snapshot IS
    'One row per opted-in user holding their latest Fitness Index axes. Refreshed by '
    'refresh_fitness_index_cohort_snapshot(); read only via compute_fitness_index_percentile.';

-- Repopulate the snapshot from the latest fitness_index_daily per user, excluding
-- users who hid their stats (profile_stats_visible = false).
CREATE OR REPLACE FUNCTION refresh_fitness_index_cohort_snapshot()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    n INTEGER;
BEGIN
    TRUNCATE fitness_index_cohort_snapshot;

    INSERT INTO fitness_index_cohort_snapshot
        (user_id, body_comp, cardio, strength, endurance, flexibility, overall, snapshot_at)
    SELECT DISTINCT ON (f.user_id)
        f.user_id, f.body_comp, f.cardio, f.strength, f.endurance, f.flexibility, f.overall, now()
    FROM fitness_index_daily f
    LEFT JOIN users u ON u.id = f.user_id
    WHERE COALESCE(u.profile_stats_visible, true) = true
    ORDER BY f.user_id, f.local_date DESC;

    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END;
$$;

-- Per-axis percentile (0-100) for one user against the cohort. NULL where the user
-- has no value for an axis OR the cohort with data for that axis is below MIN_COHORT.
CREATE OR REPLACE FUNCTION compute_fitness_index_percentile(p_user_id UUID)
RETURNS TABLE (
    axis            TEXT,
    user_value      SMALLINT,
    percentile      SMALLINT,
    cohort_size     INTEGER
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    min_cohort CONSTANT INTEGER := 30;
BEGIN
    RETURN QUERY
    WITH axes(axis) AS (
        VALUES ('body_comp'), ('cardio'), ('strength'),
               ('endurance'), ('flexibility'), ('overall')
    ),
    vals AS (
        SELECT 'body_comp'   AS axis, body_comp   AS v, user_id FROM fitness_index_cohort_snapshot
        UNION ALL SELECT 'cardio',      cardio,      user_id FROM fitness_index_cohort_snapshot
        UNION ALL SELECT 'strength',    strength,    user_id FROM fitness_index_cohort_snapshot
        UNION ALL SELECT 'endurance',   endurance,   user_id FROM fitness_index_cohort_snapshot
        UNION ALL SELECT 'flexibility', flexibility, user_id FROM fitness_index_cohort_snapshot
        UNION ALL SELECT 'overall',     overall,     user_id FROM fitness_index_cohort_snapshot
    ),
    agg AS (
        SELECT a.axis,
               (SELECT v::smallint FROM vals x WHERE x.axis = a.axis AND x.user_id = p_user_id AND x.v IS NOT NULL) AS user_value,
               (SELECT COUNT(*) FROM vals x WHERE x.axis = a.axis AND x.v IS NOT NULL)::int AS cohort_size,
               (SELECT COUNT(*) FROM vals x WHERE x.axis = a.axis AND x.v IS NOT NULL
                    AND x.v <= (SELECT y.v FROM vals y WHERE y.axis = a.axis AND y.user_id = p_user_id))::numeric AS le_count
        FROM axes a
    )
    SELECT agg.axis,
           agg.user_value,
           CASE
               WHEN agg.user_value IS NULL OR agg.cohort_size < min_cohort THEN NULL
               ELSE ROUND(100.0 * agg.le_count / NULLIF(agg.cohort_size, 0))::smallint
           END AS percentile,
           agg.cohort_size
    FROM agg;
END;
$$;
