-- Migration 2251: fitness_index_daily — daily snapshot of the 5-axis Fitness Index.
--
-- Samsung-parity "Fitness Index": a 5-axis radar (Body composition, Cardio, Strength,
-- Endurance, Flexibility) each 0-100, plus an overall, plus a "Focus" goal. Computed
-- in services/fitness_index_service.py from data we already store:
--   body_comp  <- body_measurements (body_fat %, BMI)
--   cardio     <- cardio_metrics.vo2_max_estimate
--   strength   <- performance_logs volume / est-1RM percentiles
--   endurance  <- training-load chronic capacity / cardio duration
--   flexibility<- logged mobility/stretch/yoga minutes + frequency (lowest-data axis)
--
-- This snapshot also feeds peer percentile (2252). Each user's latest row is the
-- value ranked against the cohort.
--
-- Idempotent.

CREATE TABLE IF NOT EXISTS fitness_index_daily (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    local_date      DATE NOT NULL,

    body_comp       SMALLINT,   -- 0-100, NULL when no body-comp data
    cardio          SMALLINT,
    strength        SMALLINT,
    endurance       SMALLINT,
    flexibility     SMALLINT,
    overall         SMALLINT,
    focus           TEXT,       -- e.g. 'running', 'strength' — maps to user goal

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fitness_index_daily_user_date_uniq UNIQUE (user_id, local_date)
);

CREATE INDEX IF NOT EXISTS idx_fitness_index_daily_user_date
    ON fitness_index_daily (user_id, local_date DESC);

COMMENT ON TABLE fitness_index_daily IS
    '5-axis Fitness Index snapshot (body_comp/cardio/strength/endurance/flexibility, '
    'each 0-100) + overall + focus. Axes computed in services/fitness_index_service.py. '
    'Latest row per user feeds the cohort percentile (fitness_index_cohort_snapshot).';
